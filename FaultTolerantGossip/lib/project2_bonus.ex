defmodule Project2_bonus do
  #use Supervisor
  def main(args \\ []) do
    topology=Enum.at(to_charlist(args),1) 
    {n,_}=:string.to_integer(Enum.at(to_charlist(args),0))
    algorithm=Enum.at(to_charlist(args),2)

    if "#{topology}" == "full" do
      fullyConnected = :ok
    end
    if "#{topology}" == "line" do
      line = :ok
    end
    if "#{topology}" == "2D" do
      twodGrid = :ok
    end
    if "#{topology}" == "imp2D" do
      imperfectTwod = :ok
    end
    child_list=[]
    cond do
      fullyConnected == :ok ->(
        child_list=Enum.map(1..n,fn(s) -> 
        IO.puts "I am calling direct genserver Porcess "
        {_,cid}=Actor.start_link(s) 
        cid
        end)
        #IO.inspect(pid) #supervisor's pid
        #list=Supervisor.which_children(pid)
        #IO.inspect(list)
        #child_list=(for x <- list, into: [] do
        #    {_,cid,_,_}=x
        #    cid
        #  end)
        IO.inspect(child_list)  
        for x <- child_list do
          new_list=List.delete(child_list,x) #Neighbour should not include self
          Actor.set_neighbour(x,new_list)
        end)  

      line == :ok ->( 
        child_list=Enum.map(1..n,fn(s) -> 
          IO.puts "I am calling direct genserver Porcess "
          {_,cid}=Actor.start_link(s) 
          cid
          end)
        IO.inspect(child_list)  
        child_list|>Enum.with_index|>Enum.each(fn({x, i})->
        new_list= [Enum.at(child_list, i-1),Enum.at(child_list, i+1)]
        if i==0 do
          element1=Enum.take(new_list, -1) 
          new_list=element1 |>List.wrap
        end
        if i==Enum.count(child_list)-1 do
          element1=List.first(new_list)
          new_list=element1 |> List.wrap
        end
        Actor.set_neighbour(x,new_list)
        end))
          
      twodGrid == :ok -> (  x= :math.sqrt(n)
        y= trunc(x)
        split=x
        if x>y do
          child_list=Enum.map(1..((y+1) *(y+1)),fn(s) -> 
            IO.puts "I am calling direct genserver Porcess "
            {_,cid}=Actor.start_link(s) 
            cid
            end)
          split=y+1
        else
          child_list=Enum.map(1..n,fn(s) -> 
            IO.puts "I am calling direct genserver Porcess "
            {_,cid}=Actor.start_link(s) 
            cid
            end)
        end
        IO.inspect(child_list) 
        child_list|>Enum.with_index|>Enum.each(fn({x, i})->
        split= trunc(split)
        n=trunc(split*split)
        element1=if i-1 in 0..n-1 && rem(i,split) !=0 do  Enum.at(child_list, i-1) end
        element2=if i+1 in 0..n-1 && rem(i+1,split) !=0 do Enum.at(child_list, i+1) end
        element3=if i-split in 0..n-1 do  Enum.at(child_list, i-split) end
        element4=if i+split in 0..n-1 do Enum.at(child_list, i+split) end
        new_list= [element1,element2,element3,element4]
        new_list=Enum.reject(new_list, &is_nil/1)
        Actor.set_neighbour(x,new_list)
        end))
        
      imperfectTwod == :ok ->(  x= :math.sqrt n
        y= trunc(x)
        split=x
        if x>y do
          child_list=Enum.map(1..((y+1) *(y+1)),fn(s) -> 
            IO.puts "I am calling direct genserver Porcess "
            {_,cid}=Actor.start_link(s) 
            cid
            end)
          split=y+1
        else
          child_list=Enum.map(1..n,fn(s) -> 
            IO.puts "I am calling direct genserver Porcess "
            {_,cid}=Actor.start_link(s) 
            cid
            end)
        end
        IO.inspect(child_list) 
        child_list|>Enum.with_index|>Enum.each(fn({x, i})->
        split= trunc(split)
        n=trunc(split*split)
        element1=if i-1 in 0..n-1 && rem(i,split) !=0 do  Enum.at(child_list, i-1) end
        element2=if i+1 in 0..n-1 && rem(i+1,split) !=0 do Enum.at(child_list, i+1) end
        element3=if i-split in 0..n-1 do  Enum.at(child_list, i-split) end
        element4=if i+split in 0..n-1 do Enum.at(child_list, i+split) end
        new_list= [element1,element2,element3,element4]
        new_list=Enum.reject(new_list, &is_nil/1)
        remain_list=child_list--new_list
        remain_list= remain_list--[x]
        random_actor=Enum.random(remain_list) 
        new_list=new_list++[random_actor]
        Actor.set_neighbour(x,new_list)
        end))
    end #End of Topology cond 
    killed_process=Enum.take(child_list,3)       
    if "#{algorithm}" == "gossip"do
      IO.puts "calling gossip ...." 
      #IO.inspect(self()) 
      random_node=Enum.random(child_list)
      #IO.puts("I am starting")
      #:timer.kill_after(:timer.minutes(2), self())
      Actor.parallelGossip(random_node,killed_process)
    else
      IO.puts "I am in push-sum"  
      #killed_process = killed_process
      IO.inspect(Enum.take(child_list,50))
      #Assume main process always picks Actor1 to start
      Actor.pickNextNodePushSum(Enum.at(child_list,length(child_list)-1),killed_process)
      
    end 
  end #End of main
  
end
