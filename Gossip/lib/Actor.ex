defmodule Actor do
  use GenServer

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

  def parallelGossip(pid,start_time)do
    state=Actor.get_neighbour(pid)
    count=Map.get(state,:counter)
    if(count < 11) do
      IO.inspect(pid)
      GenServer.cast(pid,{:pickNeigh,start_time})
      #:timer.sleep(100)
      IO.puts "calling myself"
      :timer.sleep(5000)
    end
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

#Handling of Parallel Gossip
def handle_cast({:pickNeigh,start_time},state) do
    pid=Map.get(state,:pid)
    #state=Map.get(state,:neigh_list)
    count=Map.get(state,:counter)
    if(count < 11 ) do
      IO.puts "Genserver parallel gossip"
      state = Map.put(state,:counter,count + 1)
      nextNode=Enum.random(Map.get(state,:neigh_list))
      GenServer.cast(nextNode,{:pickNeigh,start_time})
      #IO.puts "calling my self"
      GenServer.cast(pid,{:pickNeigh,start_time})
      :timer.sleep(100)
      #parallelGossip(nextNode)
      IO.inspect(state)
      if(count+1==11)do
        IO.puts "Time of convergence for node #{inspect(pid)}"
        IO.inspect(System.system_time(:millisecond)-start_time)
      end
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
    if count<3 do
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

 def pickNextNodePushSum(senderNode) do
    IO.puts "Inside picknextNodePushSum"
    state_sender = Actor.get_neighbour(senderNode)
    node_list = Map.get(state_sender,:neigh_list)
    receiverNode = Enum.random(node_list)
    IO.puts "Sender:"
    IO.inspect(senderNode)
    IO.puts "Receiver:"
    IO.inspect(receiverNode)
    #:timer.sleep(1000)
    state_receiver = Actor.get_neighbour(receiverNode) #To get counter of receiver Node
    counter =Map.get(state_receiver,:counter)
    if counter<3 do #Checking if receiver node is active
      state_sender = Actor.initpushSum(senderNode)
      s = Map.get(state_sender,:s)
      w = Map.get(state_sender,:w)
      swList=[s,w]
      Actor.pushSum(receiverNode,swList)
      pickNextNodePushSum(receiverNode)
    else
      updated_list= List.delete(node_list,receiverNode)
      Actor.set_neighbour(senderNode,updated_list)
      IO.puts "Receiver counter reached threshold. Picking from:"
      IO.inspect(updated_list)
      if length(updated_list) >0 do
         pickNextNodePushSum(senderNode)
      end
    end
    IO.puts "Program Converged"
 end
end

#Supervisor
defmodule Node.Supervisor do
    use Supervisor
    def start_link(n) do
        {myInt, _} = :string.to_integer(to_charlist(n))
        IO.puts myInt
        Supervisor.start_link(__MODULE__,n )
    end

    def init(myInt) do
       IO.puts myInt
       children =Enum.map(1..myInt, fn(s) -> 
            IO.puts "I am in supervisor init"
            worker(Actor,[s],[id: "#{s}"]) 
            end)
        supervise(children, strategy: :one_for_one)
    end
end
