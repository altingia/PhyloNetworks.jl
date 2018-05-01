"""
    discrete_tree_corelikelihood(tree, tips, logtrans, forwardlik, directlik)

Calculate likelihood of discrete character states on a phylogenetic network given
starting states.

"""
function discrete_tree_corelikelihood(tree::HybridNetwork, tips::Dict{String,Int64},
    logtrans::AbstractArray, forwardlik::AbstractArray, directlik::AbstractArray)
    k=size(logtrans)[1]
    for ni in reverse(1:length(tree.nodes_changed)) # post-order
        n = tree.nodes_changed[ni]
        if n.leaf
            # assumes that forwardlik was initialized at 0.0
            tiplabel = n.name
            if haskey(tips, tiplabel)
                for i in 1:k
                    forwardlik[i,ni] = -Inf64
                end
                forwardlik[tips[n.name], ni] = 0.
            end
        else
            for e in n.edge
                if n == getParent(e) 
                    continue
                end
                # excluded parent edges only: assuming tree here
                forwardlik[:,ni] += directlik[:,e.number]
            end
        end
        if ni==1 # root is first index in nodes changed
            logprior = [-log(k) for i in 1:k] # uniform prior; could be changed later based on user input
            loglik = logprior[1] + forwardlik[1,ni] # log of prob of data AND root in state 1
            for i in 2:k
                loglik = logsumexp(loglik, logprior[i] + forwardlik[i,ni])
            end
            return loglik
        end
        # if we keep going: not the root
        for e in n.edge
            if n == getChild(e)
                lt = view(logtrans, :,:,e.number)
                directlik[:,e.number] = lt[:,1] + forwardlik[1,ni]
                for i in 1:k # state at parent node
                    for j in 2:k # j = state at node n
                        tmp = lt[i,j] + forwardlik[j,ni]
                        directlik[i,e.number] = logsumexp(directlik[i,e.number],tmp)
                    end
                end
                break # we visited the parent edge: break out of for loop
            end
        end
    end
end

"""
    function discrete_tree_core_ancestralstate(tree, tips, logtrans, forwardlik, 
        directlik, backwardlik)

Ancestral state reconstruction at node n

# Examples

"""

function discrete_tree_core_ancestralstate(tree::HybridNetwork, tips::Dict{String,Int64},
    logtrans::AbstractArray, forwardlik::AbstractArray, directlik::AbstractArray,
    backwardlik::AbstractArray)
    #fixit pass k from k=nStates(mod)
    k=size(logtrans)[1]
    for n in tree.nodes_changed
        if n.root
            backwardlik[:,n] = logprior # fixit: log prior is not yet defined
        else
            pn = n.isChild1 ? 1 : 2
            for e in n.edge
                pe = e.isChild1 ? 1 : 2
            end 
            for i in 1:k
                for j in 1:k
                    tmp = backwardlik[j,pn] +logtrans[j,i,pn] + # Fixit: sum child of pn: directlik[j,e]
                    if j==1
                        backwardlik[i,n] = tmp
                    elseif j > 1
                        backwardlik[i,n] = logsumexp(backwardlik[i,n],tmp)
                    end
                end
            end
        end
    end
    return loglik
end

"""
    discrete_corelikelihood(tips, mod, trees, ltw,
        logtrans,forwardlik,directlik,backwardlik)

Calculate likelihood for discrete characters on a network,
using fixed model parameters

# Examples

"""

function discrete_corelikelihood(tips::Dict{String,Int64}, mod::TraitSubstitutionModel,
    trees::Array{HybridNetwork}, ltw::AbstractVector, logtrans::AbstractArray,
    forwardlik::AbstractArray, directlik::AbstractArray, backwardlik::AbstractArray)
    ll = Array{Float64,1}(length(trees))
    for t in 1:length(trees)
        ll[t] = discrete_tree_corelikelihood(trees[t],tips,logtrans,
                   view(forwardlik, :,:,t),view(directlik, :,:,t))
    end
    #f(t) = discrete_tree_corelikelihood(trees[t],tips,logtrans,view(forwardlik,:,:,t),
    #         view(directlik,:,:,t),view(backwardlik,:,:,t))
    #ll = pmap(f, 1:length(trees)) # ll = loglikelihood given each tree
    @show ll
    res = ll[1] + ltw[1] # result: loglikelihood given the network
    @show ltw[1]
    @show res
    for t in 2:length(trees)
        res = logsumexp(res, ll[t] + ltw[t])
    end
    return res
end

"""
    discrete_optimlikelihood(tips, mod, net)

Calculate likelihood of discrete character states on a reticulate network.

Tips should have values that are consecutive numbers

"""

function discrete_optimlikelihood(tips::Dict{String,Int64}, mod::TraitSubstitutionModel, net::HybridNetwork)
    # fixit new function to detect number of states, make model labels compatible with julia indexing
    trees = displayedTrees(net, 0.0)
    for tree in trees
        preorder!(tree)
        directEdges!(tree)
    end    
    #tips::Dict{Int64,Set{T}}
    ntrees = length(trees)
    k = nStates(mod)
    #both mlik and logtrans should be 3-d arrays
    #mlik[i,n,t] = log P{data below n in tree t given state i above n}
    # fixit: re-number edges to be consective, positive numbers; check edges are positive numbers
    #keep track of largest edge number
    #initialize 3d array: Array{Float64}((i,j,e))
    # fixit: later change the arrays below into SharedArray
    forwardlik = zeros(Float64, k,length(net.node),ntrees)
    directlik  = zeros(Float64, k,length(net.edge),ntrees)
    backwardlik= Array{Float64}(k,length(net.node),ntrees)
    #logtrans[i,j,e]; i = start_state, j = end_state, e = edge.number
    #Step 1
    ltw = Array{Float64,1}(length(trees))
    t = 0
    for tree in trees
        t+=1
        ltw[t] = 0.0
        for e in tree.edge
            if e.gamma != 1.0
                ltw[t] += log(e.gamma)
            end
        end
    end
    #Step 2
    logtrans = Array{Float64}(k,k,length(net.edge))
    for edge in net.edge
        logtrans[:,:,edge.number] = log.(P(mod,edge.length)) # element-wise
    end
    #Step 3
    discrete_corelikelihood(tips,mod,trees,ltw,logtrans,forwardlik,directlik,backwardlik)
    #fixme: add optimization routine
    #fixme: return final likelihood
end
