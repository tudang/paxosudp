# ovs script to configure network on sw222
ovs-vsctl del-br br0
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=pica8
ovs-vsctl add-port br0 ge-1/1/1 vlan_mode=access tag=5 -- set Interface ge-1/1/1 type=pica8
ovs-vsctl add-port br0 ge-1/1/2 vlan_mode=access tag=2 -- set Interface ge-1/1/2 type=pica8
ovs-vsctl add-port br0 ge-1/1/3 vlan_mode=access tag=2 -- set Interface ge-1/1/3 type=pica8
ovs-vsctl add-port br0 ge-1/1/4 vlan_mode=access tag=2 -- set Interface ge-1/1/4 type=pica8
ovs-vsctl add-port br0 ge-1/1/5 vlan_mode=access tag=2 -- set Interface ge-1/1/5 type=pica8
ovs-vsctl add-port br0 ge-1/1/6 vlan_mode=access tag=4 -- set Interface ge-1/1/6 type=pica8
ovs-vsctl add-port br0 ge-1/1/7 vlan_mode=access tag=2 -- set Interface ge-1/1/7 type=pica8
ovs-vsctl add-port br0 ge-1/1/9 vlan_mode=access tag=3 -- set Interface ge-1/1/9 type=pica8
ovs-vsctl add-port br0 ge-1/1/21 vlan_mode=trunk trunks=2,3 -- set Interface ge-1/1/21 type=pica8
ovs-vsctl add-port br0 ge-1/1/22 vlan_mode=trunk trunks=2,4 -- set Interface ge-1/1/22 type=pica8
ovs-vsctl add-port br0 ge-1/1/20 vlan_mode=trunk trunks=2,5 -- set Interface ge-1/1/20 type=pica8
ovs-vsctl add-port br0 ge-1/1/31 vlan_mode=trunk trunks=2,3 -- set Interface ge-1/1/31 type=pica8
ovs-vsctl add-port br0 ge-1/1/32 vlan_mode=trunk trunks=2,4 -- set Interface ge-1/1/32 type=pica8
ovs-vsctl add-port br0 ge-1/1/30 vlan_mode=trunk trunks=2,5 -- set Interface ge-1/1/30 type=pica8
ovs-vsctl add-port br0 ge-1/1/10 vlan_mode=access tag=6 -- set Interface ge-1/1/10 type=pica8
ovs-vsctl add-port br0 ge-1/1/23 vlan_mode=trunk trunks=2,6 -- set Interface ge-1/1/23 type=pica8
ovs-vsctl add-port br0 ge-1/1/33 vlan_mode=trunk trunks=2,6 -- set Interface ge-1/1/33 type=pica8
ovs-vsctl add-port br0 ge-1/1/11 vlan_mode=access tag=7 -- set Interface ge-1/1/11 type=pica8
ovs-vsctl add-port br0 ge-1/1/24 vlan_mode=trunk trunks=2,7 -- set Interface ge-1/1/24 type=pica8
ovs-vsctl add-port br0 ge-1/1/34 vlan_mode=trunk trunks=2,7 -- set Interface ge-1/1/34 type=pica8
ovs-ofctl add-group br0 group_id=1,type=all,bucket=output:7,bucket=output:30,bucket=output:31,bucket=output:32,bucket=output:33,bucket=output:34
ovs-ofctl add-flows br0 flows5
ovs-ofctl dump-groups-desc br0
ovs-ofctl dump-flows br0
