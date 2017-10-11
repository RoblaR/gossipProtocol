defmodule Actor do
  use GenServer
  #:ets.new(:registry, [:named_table])
  #:ets.insert(:registry, {"kill_counter",0})
  def start_link(s) do
    test=GenServer.start_link(__MODULE__,s)
    IO.inspect(test)
  end

  def init(s) do
    IO.puts "Inside Actor init #{s}"
    state= %{:s=>s,:w=>1.0,:pid => self(),:neigh_list=>[],:counter=>0}
    IO.inspect(state)
    {:ok,state}
  end

  def set_neighbour(pid, neighbour_list) do
    GenServer.call(pid, {:neighbours, neighbour_list})
  end

  def get_neighbour(pid) do
    GenServer.call(pid, {:neighbours})
  end

  #def gossip(pid, msg) do
    def stop(pid) do
      GenServer.cast(pid, :stop)
    end 
  
    def handle_cast(:stop, status) do
      IO.puts "state of killed process"
      IO.inspect(status)
      {:stop, :normal, status}
    end 
  
    def terminate(reason, _status) do
      IO.puts "Asked to stop because #{inspect reason}"
      :ok 
    end 

  def parallelGossip(pid,killed_process)do
    state=Actor.get_neighbour(pid)
    count=Map.get(state,:counter)
    IO.puts "Process to be killed are"
    IO.inspect(killed_process)
    if(count < 11) do
      IO.inspect(pid)
      GenServer.cast(pid,{:pickNeigh})
      for x <- killed_process do
        IO.inspect(x)
        IO.puts "killing process"
        Actor.stop(x)
      end
    end
    :timer.sleep(1000000)
  end

  def initpushSum(pid) do
    GenServer.call(pid,{:initpushSum})
  end

  def pushSum(pid,swList) do
    GenServer.call(pid,{:swList,swList})
  end

#Handling of set_neighbour
  def handle_call({:neighbours, neighbour_list},_from,state) do
    neighbours=neighbour_list
    IO.puts "I am inside set neighbour"
    state = Map.put(state, :neigh_list, neighbour_list)
    IO.inspect(state)
    {:reply, state,state}
  end

#Handling of get_neighbour
  def handle_call({:neighbours},_from,state) do
    my_neighbour = Map.get(state,:neigh_list)
    {:reply, state, state}
  end
   
#Handling of gossip 
#   def handle_cast({:msg,msg},state) do
#   IO.puts "Inside Gossip"
#    #IO.inspect(state)
#    state = Map.put(state,:s,msg)
#    IO.inspect(state)
#    count = Map.get(state,:counter)
#    pid = Map.get(state,:pid)
#    my_neighbour = Map.get(state,:neigh_list)
#    if count<=11 do
#      count = count+1
#      state = Map.put(state,:counter, count)
#      IO.puts "Incremented count"
#      IO.inspect(state)
#      #my_neighbour = Map.get(state,:neigh_list)
#    end
#    {:noreply, state}
#  end

#Handling of Parallel Gossip
def handle_cast({:pickNeigh},state) do
    pid=Map.get(state,:pid)
    #state=Map.get(state,:neigh_list)
    count=Map.get(state,:counter)
    if(count < 11 ) do
      IO.puts "Genserver parallel gossip"
      state = Map.put(state,:counter,count + 1)
      #IO.inspect(state)
      #if(count+1 == 10)do
      #  :timer.sleep(1000)
      #  Process.exit(pid, :kill)
      #end
      nextNode=Enum.random(Map.get(state,:neigh_list))
      if(Process.alive?(nextNode))do
      GenServer.cast(nextNode,{:pickNeigh})
      end
      if(Process.alive?(pid))do
      GenServer.cast(pid,{:pickNeigh})
      end
     # :timer.sleep(100)
      #parallelGossip(nextNode)
      IO.inspect(state)
    end
    {:noreply, state}
  end

#Handling of InitPushSum
  def handle_call({:initpushSum},_from,state) do
    s =Map.get(state,:s)
    w =Map.get(state,:w)
    state = Map.put(state,:s,s/2)
    state = Map.put(state,:w,w/2)
    IO.inspect(state)
    {:reply, state,state}
  end

#Handling of pushSum
   def handle_call({:swList,swList},_from,state) do
    IO.puts "Inside pushSum"
    count = Map.get(state,:counter)
    pid=Map.get(state,:pid)
    if (Process.alive?(pid) && count<3)  do
      s = Map.get(state,:s)
      w = Map.get(state,:w)
      ratio = s/w
      new_s = s+Enum.at(swList,0)
      new_w = w+Enum.at(swList,1)
      state = Map.put(state,:s,new_s)
      state = Map.put(state,:w,new_w)
      new_ratio = new_s/new_w
      IO.puts "s = #{s}, w=#{w}, new_s = #{new_s}, new_w= #{new_w}, ratio=#{ratio},new_ratio=#{new_ratio}"
      if abs(new_ratio-ratio) < :math.pow(10,-10) do
        new_count = count+1
        state = Map.put(state,:counter,new_count)
        IO.puts "Incremented counter for "
        IO.inspect(Map.get(state,:pid))
        IO.puts "New state is:"
        IO.inspect(state)
      end 
    end
    {:reply,state,state}
  end

  def recurse(senderNode,receiverNode) do
    if(Process.alive?(receiverNode)) do
     IO.puts "Success" 
     IO.puts "Found an alive receiverNode:"
     IO.inspect(receiverNode)
     receiverNode
    else
      IO.puts "Recurssing to find an alive node"
      state_sender = Actor.get_neighbour(senderNode)
      node_list = Map.get(state_sender,:neigh_list)
      updated_list= List.delete(node_list,receiverNode)
      Actor.set_neighbour(senderNode,updated_list)
      if !(updated_list==[]) do
        receiverNode1 = Enum.random(updated_list)
        recurse(senderNode,receiverNode1)
      end
    end
  end

 def pickNextNodePushSum(senderNode,killed_process) do
    if(Process.alive?(senderNode)) do
    IO.puts "Killed Process are"
    IO.inspect(killed_process)
    if !(killed_process==[]) do
      IO.puts "Process to be killed are"
      IO.inspect(killed_process)
      for x <- killed_process do
        if(Process.alive?(x)) do
          IO.inspect(x)
          IO.puts "killing process"
          #:timer.sleep(1000)
          Actor.stop(x)  
        end
      end

    end
    #process = GenServer.whereis(server)
    #monitor = Process.monitor(process)
    IO.puts "Inside pick"
    state_sender = Actor.get_neighbour(senderNode)
    node_list = Map.get(state_sender,:neigh_list)
    IO.puts "Listing the alive processes:"
    :timer.sleep(500)
    for x <- node_list do
        if(Process.alive?(x)) do
          IO.inspect(x)
          IO.puts "is live."
          #:timer.sleep(1000)
        end
      end
    receiverNode = recurse(senderNode,Enum.random(node_list)) #Making sure we get only alive receiverNodes
    IO.puts "Sender:"
    IO.inspect(senderNode)
    IO.puts "Receiver:"
    IO.inspect(receiverNode)
    #IO.puts "1"
    state_receiver = Actor.get_neighbour(receiverNode) #To get counter of receiver Node
    #IO.puts "2"
    counter =Map.get(state_receiver,:counter)
    IO.puts "Counter is:"
    IO.inspect(counter)
    if (counter<3) do 
      state_sender = Actor.initpushSum(senderNode)
      s = Map.get(state_sender,:s)
      w = Map.get(state_sender,:w)
      swList=[s,w]
      Actor.pushSum(receiverNode,swList)
      pickNextNodePushSum(receiverNode,[])
    else
      updated_list= List.delete(node_list,receiverNode)
      Actor.set_neighbour(senderNode,updated_list)
      IO.puts "Receiver counter reached threshold. Picking from:"
      IO.inspect(updated_list)
      if length(updated_list) >0 do
          pickNextNodePushSum(senderNode,[])
      end
    end
  end #End of senderAlive
IO.puts "Program Converged"
end#End of pickNextNodePushsum

end

#Supervisor
#defmodule Node.Supervisor do
#    use Supervisor
#    def start_link(n) do
#        {myInt, _} = :string.to_integer(to_charlist(n))
#        IO.puts myInt
#        Supervisor.start_link(__MODULE__,n )
#    end

#    def init(myInt) do
#       IO.puts myInt
#       children =Enum.map(1..myInt, fn(s) -> 
#            IO.puts "I am in supervisor init"
#            worker(Actor,[s],[id: "#{s}"]) 
#            end)
#        supervise(children, strategy: :one_for_one)
#    end
#end
