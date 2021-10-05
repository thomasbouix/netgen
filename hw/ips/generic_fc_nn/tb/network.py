#!/usr/bin/python

# inputs
inputs = [1, 0]

# weights [outputs][inputs]
w0 = [ [1, 1], [1, 1], [1, 1], [1, 1] ]
w1 = [ [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1] ]
w2 = [ [1, 1, 1], [1, 1, 1] ]
w3 = [ [1, 1], [1, 1], [1, 1], [1, 1] ]
w4 = [ [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1] ]

# bias[outputs]
b0 = [0, 1, 0, 0]
b1 = [0, 0, 0]
b2 = [0, 0]
b3 = [0, 0, 0, 0]
b4 = [0, 0, 0, -1]

# neurons output
n0 = [0, 0, 0, 0]
n1 = [0, 0, 0]
n2 = [0, 0]
n3 = [0, 0, 0, 0]
n4 = [0, 0, 0, 0]

def print_list(l) :
    for i in range(len(l)) :
        print(l[i], end=" ")
    print()

def compute_layer_0() :
    for i in range(len(n0)) :               # for each neuron  
        n0[i] = b0[i] 
        for j in range(len(inputs)) :       # for each input
            n0[i] += w0[i][j] * inputs[j]
def compute_layer_1() :
    for i in range(len(n1)) :               
        n1[i] = b1[i]
        for j in range(len(n0)) :        
            # print("n1[", i,"] += w1[", i,"][", j,"] * n0[", j,"]")
            n1[i] += w1[i][j] * n0[j]
def compute_layer_2() :
    for i in range(len(n2)) :               
        n2[i] = b2[i]
        for j in range(len(n1)) :        
            n2[i] += w2[i][j] * n1[j]
def compute_layer_3() :
    for i in range(len(n3)) :               
        n3[i] = b3[i]
        for j in range(len(n2)) :        
            n3[i] += w3[i][j] * n2[j]
def compute_layer_4() :
    for i in range(len(n4)) :               
        n4[i] = b4[i]
        for j in range(len(n3)) :        
            n4[i] += w4[i][j] * n3[j]

def forward() : 

    compute_layer_0()
    compute_layer_1()
    compute_layer_2()
    compute_layer_3()
    compute_layer_4()

    print("inputs   : ", end=" "); print_list(inputs); 
    print("----------------------------------------");
    print("n0       : ", end=" "); print_list(n0)
    print("n1       : ", end=" "); print_list(n1)
    print("n2       : ", end=" "); print_list(n2)
    print("n3       : ", end=" "); print_list(n3)
    print("n4       : ", end=" "); print_list(n4)
    print("----------------------------------------");

### MAIN ###
forward()
