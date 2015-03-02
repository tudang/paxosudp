/*
 * Copyright (c) 2013-2014, University of Lugano
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the copyright holders nor the names of it
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include "peers.h"
#include "message.h"
#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <event2/buffer.h>
#include <event2/bufferevent.h>
#include <event2/listener.h>

#define MAXBUFLEN 64000

struct subscription
{
	paxos_message_type type;
	peer_cb callback;
	void* arg;
};

struct peers
{
	int peers_count, clients_count;
	struct peer** peers;   /* peers we connected to */
	struct peer** clients; /* peers we accepted connections from */
	struct evconnlistener* listener;
	// replace listener with a socket and event
	int bind_fd;
	int use_mcast;
	char* mcast_addr;
	struct event* recv_ev;
	struct event_base* base;
	struct evpaxos_config* config;
	int subs_count;
	struct subscription subs[32];
};

static struct timeval reconnect_timeout = {2,0};
static struct peer* make_peer(struct peers* p, int id, struct sockaddr_in* in);
static void free_peer(struct peer* p);
static void free_all_peers(struct peer** p, int count);
//static void connect_peer(struct peer* p);
static void peers_connect(struct peers* p, int id, struct sockaddr_in* addr);
static void on_read(int fd, short event, void* arg);
static void on_connection_timeout(int fd, short ev, void* arg);
static void on_listener_error(struct evconnlistener* l, void* arg);
static void on_accept(struct evconnlistener *l, evutil_socket_t fd,
	struct sockaddr* addr, int socklen, void *arg);


struct peers*
peers_new(struct event_base* base, struct evpaxos_config* config)
{
	struct peers* p = malloc(sizeof(struct peers));
	p->peers_count = 0;
	p->clients_count = 0;
	p->subs_count = 0;
	p->peers = NULL;
	p->clients = NULL;
	p->listener = NULL;
	p->base = base;
	p->config = config;
	p->use_mcast = 0;
	return p;
}

struct peers*
peers_mcast_new(struct event_base* base, struct evpaxos_config* config,
	char* mcast_address)
{
	struct peers* p = peers_new(base, config);
	p->use_mcast = 1;
	p->mcast_addr = mcast_address;
	return p;
}

void
peers_free(struct peers* p)
{
	free_all_peers(p->peers, p->peers_count);
	free_all_peers(p->clients, p->clients_count);
	if (p->listener != NULL)
		evconnlistener_free(p->listener);
	free(p);
}


void
peers_create_clients(struct peers* p)
{
  int i;
  struct sockaddr_in addr;
  for (i = 0; i < evpaxos_proposer_count(p->config); i++) {
    addr = evpaxos_proposer_address(p->config, i);
    p->clients = realloc(p->clients,
			 sizeof(struct peer*) * (p->clients_count+1));
    p->clients[p->clients_count] = make_peer(p, i, (struct sockaddr_in*)&addr);
	p->clients[p->clients_count]->is_proposer = 1;
    p->clients_count++;
  }
  for (i = 0; i < evpaxos_learner_count(p->config); i++) {
    addr = evpaxos_learner_address(p->config, i);
    p->clients = realloc(p->clients,
			 sizeof(struct peer*) * (p->clients_count+1));
    p->clients[p->clients_count] = make_peer(p, i, (struct sockaddr_in*)&addr);
	p->clients[p->clients_count]->is_proposer = 0;
    p->clients_count++;
  }
}

int
peers_count(struct peers* p)
{
	return p->peers_count;
}

struct peer*
peers_get_client(struct peers* p, int i)
{
	return p->clients[i];
}

struct peer*
peers_get_peer(struct peers* p, int i)
{
	return p->peers[i];
}

// create a simple socket instead of bufferevent
static void
peers_connect(struct peers* p, int id, struct sockaddr_in* addr)
{
	p->peers = realloc(p->peers, sizeof(struct peer*) * (p->peers_count+1));
	p->peers[p->peers_count] = make_peer(p, id, addr);
	
	struct peer* peer = p->peers[p->peers_count];
	//bufferevent_setcb(peer->bev, on_read, NULL, on_peer_event, peer);
	//	peer->reconnect_ev = evtimer_new(p->base, on_connection_timeout, peer);
	//	connect_peer(peer);

	p->peers_count++;
}

void
peers_connect_to_acceptors(struct peers* p)
{
	int i;
	for (i = 0; i < evpaxos_acceptor_count(p->config); i++) {
		struct sockaddr_in addr = evpaxos_acceptor_address(p->config, i);
		peers_connect(p, i, &addr);
	}
}

void
peers_foreach_acceptor(struct peers* p, peer_iter_cb cb, void* arg)
{
	int i;
	for (i = 0; i < p->peers_count; ++i)
		cb(p->peers[i], arg);
}

void
peers_foreach_client(struct peers* p, peer_iter_cb cb, void* arg)
{
	int i;
	for (i = 0; i < p->clients_count; ++i)
		cb(p->clients[i], arg);
}

struct peer*
peers_get_acceptor(struct peers* p, int id)
{
	int i;
	for (i = 0; p->peers_count; ++i)
		if (p->peers[i]->id == id)
			return p->peers[i];
	return NULL;
}

int
peer_is_proposer(struct peer* p)
{
	return p->is_proposer;
}

// return socket instead of bufferevent
/*
peer_get_buffer(struct peer* p)
change to get_peer_sockfd
*/
struct sockaddr_in*
peer_get_buffer(struct peer* p)
{
	return &(p->addr);
}

int
peer_get_id(struct peer* p)
{
	return p->id;
}

int peer_connected(struct peer* p)
{
	return p->status == BEV_EVENT_CONNECTED;
}


// bind socket, remove evconnlistener_new_bind
int
peers_listen(struct peers* p, int port)
{
	struct sockaddr_in addr;

	p->bind_fd = socket(AF_INET, SOCK_DGRAM, 0);

	/* listen on the given port at address 0.0.0.0 */
	memset(&addr, 0, sizeof(struct sockaddr_in));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	addr.sin_port = htons(port);
	
	evutil_make_socket_nonblocking(p->bind_fd);
	bind(p->bind_fd, (struct sockaddr*)&addr, sizeof(struct sockaddr_in));
		
	if (p->use_mcast) {
		// memset(&addr, 0, sizeof(struct sockaddr_in));
		// addr.sin_family = AF_INET;
		// addr.sin_addr.s_addr = htonl(p->mcast_addr);
		// addr.sin_port = htons(port);
		struct ip_mreq mreq;
		mreq.imr_multiaddr.s_addr = inet_addr(p->mcast_addr);
		mreq.imr_interface.s_addr = htonl(INADDR_ANY);
		if (setsockopt(p->bind_fd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq)) != 0) {
			perror("setsockopt, setting IP_ADD_MEMBERSHIP");
			return -1;
		}
	}
	

	
	p->recv_ev = event_new(p->base, p->bind_fd, EV_READ|EV_PERSIST, on_read, p);
	event_add(p->recv_ev, NULL);
	
	paxos_log_info("Listening on port %d", port);
	return p->bind_fd;
}

void
peers_subscribe(struct peers* p, paxos_message_type type, peer_cb cb, void* arg)
{
	struct subscription* sub = &p->subs[p->subs_count];
	sub->type = type;
	sub->callback = cb;
	sub->arg = arg;
	p->subs_count++;
}

struct event_base*
peers_get_event_base(struct peers* p)
{
	return p->base;
}

static void
dispatch_message(struct peers* peers, struct peer* p, paxos_message* msg)
{
	int i;
	for (i = 0; i < peers->subs_count; ++i) {
		struct subscription* sub = &peers->subs[i];
		if (sub->type == msg->type)
			sub->callback(p, msg, sub->arg);
	}
}


struct peer*
match_addr(struct peer** peers, int count, struct sockaddr* addr)
{
	int i;
	for (i=0; i<count; i++) {
		if (evutil_sockaddr_cmp((struct sockaddr*)&(peers[i]->addr), addr, 1) == 0)
			return peers[i];
	}
	return NULL;
}

struct peer*
get_peer(struct peers* peers, struct sockaddr* addr)
{
  //printf("%d\n", peers->clients_count);
  struct peer* p = match_addr(peers->clients, peers->clients_count, addr);
  if (p != NULL) return p;
  return match_addr(peers->peers, peers->peers_count, addr);
}

#include <msgpack.h>
#include "paxos_types_pack.h"

// replace bufferevent_* with read/readfrom
// recv_paxos_message() is in file message.c
static void
on_read(int fd, short event, void* arg)
{
	paxos_message out;
	int numbytes;
	struct sockaddr_in addr;
	socklen_t socklen = sizeof(addr);
	char buf[MAXBUFLEN];
	struct peers* peers = (struct peers*)arg;

	if ((numbytes = recvfrom(fd, buf, (MAXBUFLEN-1), 0,
				 (struct sockaddr*)&addr, &socklen)) == -1) {
		perror("on_read: recvfrom");
		exit(1);
	}
    
	printf("%d\n", ntohs(addr.sin_port));
	char buffer[20];
	inet_ntop(AF_INET, &(addr.sin_addr), buffer, 20);
	printf("%s\n", buffer);
	
	struct peer* p = NULL;
	if (!peers->use_mcast) {
		p = get_peer(peers, (struct sockaddr*)&addr);
		assert(p != NULL);
	}
	
	size_t offset = 0;
	msgpack_unpacked msg;
	msgpack_unpacked_init(&msg);
	msgpack_unpack_next(&msg, buf, numbytes, &offset);
	msgpack_unpack_paxos_message(&msg.data, &out);
	dispatch_message(peers, p, &out);
	msgpack_unpacked_destroy(&msg);
}

static void
on_connection_timeout(int fd, short ev, void* arg)
{
  //	connect_peer((struct peer*)arg);
}

static void
on_listener_error(struct evconnlistener* l, void* arg)
{
	int err = EVUTIL_SOCKET_ERROR();
	struct event_base *base = evconnlistener_get_base(l);
	paxos_log_error("Listener error %d: %s. Shutting down event loop.", err,
		evutil_socket_error_to_string(err));
	event_base_loopexit(base, NULL);
}

/*static void
on_accept(struct evconnlistener *l, evutil_socket_t fd,
	struct sockaddr* addr, int socklen, void *arg)
{
	struct peer* peer;
	struct peers* peers = arg;

	peers->clients = realloc(peers->clients,
		sizeof(struct peer*) * (peers->clients_count+1));
	peers->clients[peers->clients_count] = 
		make_peer(peers, peers->clients_count, (struct sockaddr_in*)addr);
	
	peer = peers->clients[peers->clients_count];
	//bufferevent_setfd(peer->bev, fd);
	//bufferevent_setcb(peer->bev, on_read, NULL, on_client_event, peer);
	//bufferevent_enable(peer->bev, EV_READ|EV_WRITE);
	peer->peer_sockfd = (int) fd;
	peers->recv_ev = event_new(peers->base, peers->bind_fd, EV_READ, on_read, NULL);
	paxos_log_info("Accepted connection from %s:%d",
		inet_ntoa(((struct sockaddr_in*)addr)->sin_addr),
		ntohs(((struct sockaddr_in*)addr)->sin_port));
	
	peers->clients_count++;
	}*/


// connect udp socket instead of bufferevent
 /*static void
connect_peer(struct peer* p)
{	

	connect(p->peer_sockfd, (struct sockaddr*)&p->addr, sizeof(p->addr));

	paxos_log_info("Connect to %s:%d", 
		inet_ntoa(p->addr.sin_addr), ntohs(p->addr.sin_port));
}
 */

// change according  to struct peer
static struct peer*
make_peer(struct peers* peers, int id, struct sockaddr_in* addr)
{
	struct peer* p = malloc(sizeof(struct peer));
	p->id = id;
	p->addr = *addr;
	p->peer_sockfd = peers->bind_fd;

	  //  socket(AF_INET, SOCK_DGRAM, 0);
	  //	if (p->peer_sockfd < 0) {
	  //		perror("make_peer: socket");
	  //	exit(1);
	  //}
	p->peers = peers;
	p->reconnect_ev = NULL;
	p->status = BEV_EVENT_EOF;
	return p;
}

static void
free_all_peers(struct peer** p, int count)
{
	int i;
	for (i = 0; i < count; i++)
		free_peer(p[i]);
	if (count > 0)
		free(p);
}

static void
free_peer(struct peer* p)
{
	//bufferevent_free(p->bev);
	if (p->reconnect_ev != NULL)
		event_free(p->reconnect_ev);
	free(p);
}
