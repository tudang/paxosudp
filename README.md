## Building

Simple,

```
./setup.sh
```

## Running the examples

REMEMBER: Match IP address in udppaxos.conf and demo.cfg
e.g, 
in udppaxos.conf
acceptor 0 192.168.3.70 8800

in demo.cfg
[acceptor]
addr1=192.168.3.70
```
python run_demo.py
cat *.dat
```


## Configuration

See ```udppaxos.conf``` for a sample configuration file.

##  Unit tests

Unit tests depend on the [Google Test][4] library. Execute the tests using 
```make test``` in your build directory, or run ```runtest``` from
```build/unit``` for  detailed output.

## Feedback

[LibPaxos project page][1]

[LibPaxos3 repository][5]

[Mailing list][6]

## License

LibPaxos3 is distributed under the terms of the 3-clause BSD license.
LibPaxos3 has been developed at the [University of Lugano][7],
by [Daniele Sciascia][8].

[1]: http://libpaxos.sourceforge.net
[2]: http://www.libevent.org
[3]: http://www.oracle.com/technetwork/products/berkeleydb
[4]: http://code.google.com/p/googletest/
[5]: https://bitbucket.org/sciascid/libpaxos
[6]: https://lists.sourceforge.net/lists/listinfo/libpaxos-general
[7]: http://inf.usi.ch
[8]: http://atelier.inf.usi.ch/~sciascid
[9]: http://www.msgpack.org
[10]: http://symas.com/mdb/
