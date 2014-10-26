# initial tests for readTopology
# reads only a tree and with taxon number, not taxon names
# Claudia October 2014
#########################################################

include("../types.jl")
include("../functions.jl")

using Base.Collections # for updateInCycle with priority queue

# good trees ---------------------------
f = open("prueba_tree.txt","w")
tree = "((1,2),(3,4));"
tree = "((11,22),(33,44));"
tree = "((Ant,Bear),(Cat,Dog));"
tree = "((Ant1,Bear2),(Cat3,Dog4));"
tree = "((1Ant,2Bear),(3Cat,4Dog));"
tree = "((1,2),3,4);"
tree = "(1,2,(3,4));"
tree = "(Ant,Bear,(Cat,Dog));"
tree = "(A,B,(C,D));"
tree = "(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);"
tree = "((((((1,2),3),4),5),6),7,8);" # yeast data tree0
write(f,tree)
close(f)

net = readTopology("prueba_tree.txt");
printEdges(net)
printNodes(net)
net.names

# bad trees --------------------------
f = open("prueba_tree.txt","w")
tree = "(((1,2),(3,4)));" # extra parenthesis
tree = "((1,2,(3,4)));" # extra parenthesis
tree = "(((1,2),3,4));" # extra parenthesis
tree = "((1),2,3,4,5);" # not tree
tree = "((1,*),(3,4));" # not letter/number taxon name
tree = "(1,2::,(3,4));" #double :
tree = "(1,2:::,(3,4));" #triple :
tree = "(1,2:0.2:,(3,4));" #no 2nd :
tree = "(1,2:0.2:0.2:,(3,4));" #no 3rd :
tree = "(1,2:,(3,4));" #no 1st:
tree = "((1,2),(3,4))" # no ;
write(f,tree)
close(f)

net = readTopology("prueba_tree.txt");
printEdges(net)
printNodes(net)
net.names

# trees with additional info -----------------
f = open("prueba_tree.txt","w")
#tree = "((1:1.2,2:0.3),3:1.8,4);"
#tree = "((1:1.2,2:0.3):1.2:0.6:0.3,3:1.8,4);"
#tree = "((1:1.2,2:0.3):1.2::0.6,3:1.8,4);" # no bootstrap
#tree = "((1:1.2,2:0.3):::0.6,3:1.8,4);" # no length nor bootstrap
#tree = "((1:1.2,2:0.3):1.2:2.5:1.6,3:1.8,4);" # wrong value gamma
tree = "((1:1.2,2:0.3):1.2:2.5:,3:1.8,4);" # missing value gamma
write(f,tree)
close(f)

net = readTopology("prueba_tree.txt")
printEdges(net)
printNodes(net)
net.names

# beginning of networks ---------------------------
include("../types.jl")
include("../functions.jl")

using Base.Collections # for updateInCycle with priority queue


f = open("prueba_tree.txt","w")
#tree = "((1,2),3,4);"
tree = "(((6,7)9#H1,1),((8)9#H1,2));"
tree = "(((6,7)9#H1:1.2:0.9:0.4,1),((8)9#H1,2));"
#tree = "(1,2,(3,4));"
tree = "(1,2,(3,4)A);"
tree = "(1,2,(3,4)A:0.8);"
tree = "(((1)#H1,2),3,4);"
tree = "((1#H1,2),3,4);"
tree = "(#H1,2,(3,4));"
write(f,tree)
close(f)

net = readTopology("prueba_tree.txt");
printEdges(net)
printNodes(net)
net.names

