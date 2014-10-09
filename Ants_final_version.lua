-- Model: Agents - Schelling's segregation model 
--
-- Author: Fesseha Belay & Javier Morata
--
-- Lesson: Agent based models in TerraME.
-- 		   Before add agents to an environment, add all cellular space the will need.
--		   Model MUST have the following structure
--				1) Define space
--				2) Define behavior (agents or societies or groups)
--				3) Define time
--				4) Define environments (adding (1) cellular spaces, then (2) agents, then (3) timers )
--				5) Run simulations 
--

--------------------------------------------------------------
-- PARAMETER 
--------------------------------------------------------------

-- size of the society of agents
SOCIETY_SIZE	= 40
SPACE_DIMENSION = 50

-- simulationn temporal extent
FINAL_TIME = 1000

-- Pieces of food
NUM_FOOD = 3

-- Amount of food in each piece
SIZE_FOOD = 10

-- controls the diffusion rate of the chemical
RATE_DIFFUSION = 2    -- 3,  4

-- controls the evaporation rate of the chemical
RATE_EVAPORATION = 0.25 -- 0.5,  0.75



--------------------------------------------------------------
-- GLOBAL 
--------------------------------------------------------------

-- Possible states
EMPTY	 = 0
FOOD     = 1
NEST     = 2
CHEMICAL = 3
LESSCHEM = 4	
ANT 	 = 5  	

SEARCHING_FOOD = 5
BRINGING_FOOD = 6

-- Possible movements
MOVE_CHEM = 7
MOVE_LESS = 8
MOVE_RAND = 9

COUNTER_FOOD = 75   -- Pieces of food (This is the amount of food depending on the cells painted as FOOD)

-- random number generator
rand = Random()



--------------------------------------------------------------
-- MODEL 
--------------------------------------------------------------

-------------
--# SPACE #
-------------

cs = CellularSpace {
	xdim = SPACE_DIMENSION,
	food = COUNTER_FOOD
}

cs:createNeighborhood {
    strategy = "moore", -- vonNeuman
		self = false
}

forEachCell (cs, function (cell)
	cell.cover = EMPTY
	cell.chemical = 0		
end)

-------------------------------------------------------------------
-- DRAW NEST on the center
-------------------------------------------------------------------
center_cell = Coord { x = SPACE_DIMENSION/2, y = SPACE_DIMENSION/2}
nest_cell = cs:getCell(center_cell)
nest_cell.cover = NEST
forEachNeighbor (nest_cell, function (nest_cell, neigh)
	neigh.cover = NEST
end)

-- Prepare the start cells for the ANTS
right = Coord { x = nest_cell.x + 2, y = nest_cell.y}
left = Coord { x = nest_cell.x -2, y = nest_cell.y}
up = Coord { x = nest_cell.x, y = nest_cell.y - 2}
down = Coord { x = nest_cell.x, y = nest_cell.y + 2}	
nest_cell_right = cs:getCell(right)
nest_cell_left = cs:getCell(left)
nest_cell_up = cs:getCell(up)
nest_cell_down = cs:getCell(down)

-------------------------------------------------

-------------------------------------------------------------------
-- DRAW 3 pieces of food
-------------------------------------------------------------------
coordf1 = Coord { x = SPACE_DIMENSION/8, y = SPACE_DIMENSION/8}
cell = cs:getCell(coordf1)
cell.cover = FOOD
forEachNeighbor (cell, function (cell, neigh)
	neigh.cover = FOOD
	forEachNeighbor (neigh, function (neig, neigh2)
		neigh2.cover = FOOD
	end)
end)


coordf1 = Coord { x = SPACE_DIMENSION/7, y = SPACE_DIMENSION*3/4}
cell = cs:getCell(coordf1)
cell.cover = FOOD
forEachNeighbor (cell, function (cell, neigh)
	neigh.cover = FOOD
	forEachNeighbor (neigh, function (neig, neigh2)
		neigh2.cover = FOOD
	end)
end)


coordf1 = Coord { x = SPACE_DIMENSION*3/4, y = SPACE_DIMENSION/3}
cell = cs:getCell(coordf1)
cell.cover = FOOD
forEachNeighbor (cell, function (cell, neigh)
	neigh.cover = FOOD
	forEachNeighbor (neigh, function (neig, neigh2)
		neigh2.cover = FOOD
	end)
end)

----------------
--# BEHAVIOR #
----------------

familyAnt = Agent {
	-- initialize the agent internal state
	init = function (self)
		self.state = SEARCHING_FOOD
		self.parent = soc
		self.dest = nil
		
	end,

	execute = function (self)
		
		moveAnts(self)		
		
	end
}

soc = Society {
	instance = familyAnt, 
	quantity = SOCIETY_SIZE
}


function moveAnts(agent)
	
	if agent.state == SEARCHING_FOOD then
	
		if (findFood(agent)==false) then
			
			cell = agent:getCell()
			
			any_chem = false
		
			-- If ANT find chemical go there
			forEachNeighbor (cell, function (cell, neigh)
					if (neigh.cover == CHEMICAL) then
						cell.cover = EMPTY
						agent:move(neigh)
						--##neigh.cover = ANT
						any_chem = true
					end
			end)
			
			-- If ANT find lesschemical go there
			forEachNeighbor (cell, function (cell, neigh)
					if (neigh.cover == CHEMICAL) then
						cell.cover = EMPTY
						agent:move(neigh)
						--##neigh.cover = ANT
						any_chem = true
					end
			end)
			
			if ( any_chem == false) then
				
				if ( agent.dest ~=nil) then	
					goto_cell(agent)
				else
					agent.dest = cs:sample()
					goto_cell(agent)
				end
				
				
			end
		else	-- If find food through a lot chemical
			
		end	

	elseif agent.state == BRINGING_FOOD then  
		
		if (findNest(agent)  == false) then
			
			cell = agent:getCell()
			
			-- Search next coordinate X to come bak to the nest
			if (cell.x < nest_cell.x) then
				new_x = cell.x + 1
			elseif (cell.x > nest_cell.x) then
				new_x = cell.x - 1
			else
				new_x = cell.x
			end
			
			-- Search next coordinate Y to come bak to the nest
			if (cell.y < nest_cell.y) then
				new_y = cell.y + 1
			elseif (cell.y > nest_cell.y) then
				new_y = cell.y - 1
			else
				new_y = cell.y
			end
				
			
			new_coord = Coord { x = new_x, y = new_y}
			new_cell = cs:getCell(new_coord)
			
			if (new_cell.cover ~= FOOD) and (new_cell.cover ~= NEST) then
				agent:getCell().cover = CHEMICAL	
				agent:getCell().chemical = agent:getCell().chemical + RATE_DIFFUSION
				
				forEachNeighbor (cell, function (cell, neigh)
					if (neigh.cover ~= FOOD) and (neigh.cover ~= NEST) and (neigh.cover ~= CHEMICAL) then
						neigh.chemical = neigh.chemical + (RATE_DIFFUSION / 2)
						if (neigh.chemical > 0) and (neigh.chemical <= 1) then
							neigh.cover = LESSCHEM
						elseif (neigh.chemical>1) then
							neigh.cover = CHEMICAL
						end
					end
				end)
				
				agent:move(new_cell)
				
			elseif new_cell.cover == FOOD then
				cell = agent:getCell():getNeighborhood():sample()
				if cell.cover == EMPTY then
					agent:move(cell)
				end
			end
		
		end
		
	end	
		
end

-- Searching for FOOD
function findFood(agent) 
	cell = agent:getCell()
	forEachNeighbor (cell, function (cell, neigh)
		if neigh.cover == FOOD then
			--agent:getCell().cover = EMPTY		
			--agent:move(neigh)
			--neigh.cover = ANT
			-- FLAGS
			
			neigh.cover = CHEMICAL
			
			cell = agent:getCell()
			forEachNeighbor (cell, function (cell, neigh)
				if (neigh.cover ~= FOOD) and (neigh.cover ~= NEST) then
					neigh.cover = CHEMICAL
					neigh.chemical = neigh.chemical + RATE_DIFFUSION
					forEachNeighbor (neigh, function (neigh, neigh2)
						if (neigh2.cover ~= FOOD) and (neigh2.cover ~= NEST) then
							neigh2.cover = LESSCHEM
							neigh2.chemical = neigh2.chemical + RATE_DIFFUSION/2
					
						end
					end)
				end
			end)
			
			agent.state = BRINGING_FOOD
			cs.food = cs.food - 1
			return true
		end
		
	end)
	return false
end

-- Searching for FOOD
function findNest(agent) 
	cell = agent:getCell()
	forEachNeighbor (cell, function (cell, neigh)
		if neigh.cover == NEST then
			agent.state = SEARCHING_FOOD
			return true
		end
		
	end)
	return false
end


function goto_cell(agent)

		dest = agent.dest
		cell = agent:getCell()
			
		-- Search next coordinate X to come bak to the nest
		if (cell.x < dest.x) then
			new_x = cell.x + 1
		elseif (cell.x > dest.x) then
			new_x = cell.x - 1
		else
			new_x = cell.x
		end	
	
		-- Search next coordinate Y to come bak to the nest
		if (cell.y < dest.y) then
			new_y = cell.y + 1
		elseif (cell.y > dest.y) then
			new_y = cell.y - 1
		else
			new_y = cell.y
		end	
	
		new_coord = Coord { x = new_x, y = new_y}
		new_cell = cs:getCell(new_coord)
			
		if (new_cell.cover ~= FOOD) and (new_cell.cover ~= NEST) then
			agent:move(new_cell)
		else
			new_cell = agent:getCell():getNeighborhood():sample()
			if (new_cell.cover ~= FOOD) and (new_cell.cover ~= NEST) then
				agent:move(new_cell)
			end
		end
		
		if (new_cell == dest) then
			agent.dest = nil
		end

end


-----------
--# TIME #
-----------

function myTimePrinter( ) 
	print(t:getTime().." "..COUNTER_FOOD)
end

function chemicalEvaporation() 
	forEachCell (cs, function (cell)
		if cell.chemical > 0 then	
			cell.chemical = cell.chemical - RATE_EVAPORATION
		end
		if cell.chemical <= 0 and (cell.cover == CHEMICAL or cell.cover == LESSCHEM) then
			cell.cover = EMPTY
		elseif cell.chemical < 1 and cell.cover == CHEMICAL then
			cell.cover = LESSCHEM
		end			
	end) 
end
		
t = Timer {
	Event {time = 1, period = 1, action = soc},
	Event {time = 1, period = 1, action = cs},
	Event {time = 1, period = 1, action = myTimePrinter }, -- try to comment this line
	Event {time = 1, period = 1, action = chemicalEvaporation}
}


-------------------------------------------
--# ENVIRONMENT ( SCALE or VIRTUAL WORLD) #
-------------------------------------------

-- creates the virtual world 
-- before add agents to a environment, add all cellular space the will need
env = Environment {cs, soc, t}

-- how agents will be placed inside a environment
env:createPlacement {
	strategy = "void"
}

-- initialize cells with the same color of agents living on it 
forEachAgent (soc, function (agent)
		
	
	random_start = math.random(1,4)
	
	if (random_start == 1) then
		agent:enter(nest_cell_right)
	elseif (random_start == 2) then
		agent:enter(nest_cell_left)
	elseif (random_start == 3) then
		agent:enter(nest_cell_up)
	elseif (random_start == 4) then
		agent:enter(nest_cell_down)
	end

end)




--------------------------------------------------------------
-- SIMULATION
--------------------------------------------------------------

leg = Legend {
	grouping = "uniquevalue",
	colorBar = {
		{value = EMPTY, color = "brown"},
		{value = ANT,  color = "brown"},
		{value = FOOD,   color = "blue"},
		{value = NEST,  color = "red"},   --{50,50,50},
		{value = CHEMICAL,   color = "green"}, --chemicalColor
		{value = LESSCHEM,   color = "darkGreen"}
	}
}

legAnt = Legend {
	symbol = "B",
	font = "wminsects1",
	fontSize = 8
}
	
	

map = Observer {
	type = "map",
	subject = cs,
	attributes = {"cover"},
	legends = {leg}
}

graph = Observer {
	subject = cs,	
	type = "chart",
	attributes = {"food"}
}

antSymbol = Observer {
	type = "map",
	subject = soc,
	observer = map,
	attributes = {"state"},
	legends = {legAnt}
}

-- EXECUTE THE ENVIRONMENT
env:execute(FINAL_TIME)
