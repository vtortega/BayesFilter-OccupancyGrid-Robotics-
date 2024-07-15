# Mapping and Exploration of an Unknown World with the Occupancy Grid Algorithm
**Using a Frontier-Based Approach for Autonomous Exploration**

## 1. Introduction
In situations where the environment is unknown, effective exploration strategies become crucial. This notebook delves into the realm of autonomous exploration in robotics, using the differential Kobuki robot equipped with a single 180-degree Hokuyo fast laser sensor, with a maximum range of 5 meters. This robot, similar to traditional vacuum cleaning robots, operates within predefined simulation scenes. We conduct experiments in both static and dynamic environments to assess performance under varying conditions.

<img width="2484" alt="Screenshot 2024-07-14 at 14 40 30" src="https://github.com/user-attachments/assets/3cec99a8-8afb-4062-aec8-ad0cdff3b97a">

### Problem Overview
The primary challenge addressed in this project is the effective exploration and mapping of an environment using a robot. Key aspects include handling sensor noise and determining an efficient maping and navigation strategy.

### Robot and Environment
- **Robot Model:** Kobuki Differential Robot
- **Sensor:** Hokuyo Fast Laser Sensor (180 degrees, 5 meters max range)
- **Simulation:** CoppeliaSim with predefined scenes
- **Scenarios:** Static and dynamic environments (a person walking in the room adds complexity)

<img width="1666" alt="Screenshot 2024-07-15 at 04 41 01" src="https://github.com/user-attachments/assets/602eb24f-cc76-4656-8aa0-c13cb496f98d">

### Experimental Variations
We experimented with different cell sizes, sensor precisions, noise levels, and navigation algorithms to identify the optimal path to the objective point. Notably, the robot's position is provided by the Coppelia simulator, ensuring accurate localization.

## 2. Execution of the Program
### Requirements
- **Simulator:** CoppeliaSim
- **Libraries:** Python with Matplotlib, NumPy, math, time, SciPy, Skimage, heapq, os, and ZeroMQ API

  It's worth noting that, between the 4 notebooks, there are some small diferences made to some parameters, as asked by the environment. Fell free to mess with them too. But keep in mind that dynamic maps asks for a dynamic robot, so it doesn't get run over.
  
  Variation may and will happen between runs, it's impossible to guarantee a perfect functional system with as simple elements and such complex task, but it is sufficient enough that it was possible to run 5 consecutive times and get successful results every time in each notebook.
  There are limits to the robot too. If a speed of 30ms is given, it obviously won't work.
  
  Too big of a padding might leave the robot stuck looking for a path, so thats a variable you might consider changing if somthing goes wrong in finding a path.(In cell 19).
  
  Some paths just won't work because of the design of the map too. It's impossible for the robot to realize the shelf, the chair and the table are what they are. as the height of the laser delivers a false reading of reality. That's when the fixed maps come in handy.

### Setup
1. Ensure CoppeliaSim is installed and operational.
2. Place the simulation scenes in the same folder as the notebook.
3. Update the scene names in the notebook if necessary. The path is handled by the os library, so only the scene names need updating.

### Running the Program
To execute the program, ensure all dependencies are installed and run the main script in the notebook. Adjust the scene names in the code if the default names are changed.

## 3. Approach for Solving the Problem
### Mapping
A basic Bayes Filter with a static state and log odds is used for mapping. Each cell is attributed a probability of being occupied, which can be interpreted as unoccupied, occupied, or unknown, intervals for each of this possibilites are defined for reducing the log odds grid into a ternary grid.

### Navigation
For navigation, we implemented the [Brian Yamauchi frontier-based approach](https://faculty.iiit.ac.in/~mkrishna/YamauchiFrontier.pdf). This method focuses on exploring the nearest or largest frontier available after updating the grid based on the Bayes Filter.

<p align="center">
<img width="738" alt="Screenshot 2024-07-14 at 16 23 30" src="https://github.com/user-attachments/assets/c0cedbd5-0670-41cb-a8d1-672a20bff882">
<p/>

### Control
The robot's movement is controlled using a set of four motions: **Right**, **Left**, **Forward**, **Backward**

<p align="center">
<img width="186" alt="Screenshot 2024-07-15 at 04 45 59" src="https://github.com/user-attachments/assets/3630803b-fafc-445d-bfed-0a9d895d2247">
<p/>

These motions are tailored for differential drive systems.

## 4. Implementation

### Basics
The foundation of the program is built on essential functions that perform coordinate transformations and manage the occupancy grid updates. These include:

#### Coordinate Transformations
1. **Robot to World Transformation:** Converts coordinates from the robot's frame of reference to the world frame.
2. **World to Robot Transformation:** Converts coordinates from the world frame back to the robot's frame of reference.

#### Log Odds Function
The log odds function implements the Bayes Filter formula. It includes two utility functions:
- **Log Odds function:** Implements the Bayes filter function, with log odds.
- **Probability to Odds:** Converts probability values to odds.
- **Odds to Probability:** Converts odds back to probability values.

#### Sensor Data Processing
A function processes the sensor data by:
1. Retrieving sensor readings in radians and distances.
2. Transforming these readings into an array of points in the robot's coordinates.
3. Filtering out points that are too distant or too close. The sensor considers a reading of 5 meters as "nothing detected" and close readings are used for the reactive part of the algorithm.

**If wanted, inside the funtion its possible to add angle os distance noise.**

### Control of the Differential Robot
The control mechanism for the differential robot includes three key functions, each of them has a update grid function inside to update the grid as the robot moves:

1. **360-Degree Rotation:**
   - This function makes the robot rotate 360 degrees by setting the velocities of each wheel in opposite directions. 
   - It is useful for recognizing the environment before planning the next move.

3. **Rotation:**
   - Turns the robot in the desired amount of radians.

3. **Move to a point:**
   - Uses the rotation function to align the angle of the robot with the desired destination and sets the velocity of the wheels equal to each other, stopping when near the goal point.
   - If any object is unexpectedly close, the robot goes back and makes a new planning based on the inforamtion collected. 

## Grid operations
All operations made to get and with the grid of log odds.

### Inverse Sensor Model
The inverse sensor model is crucial for interpreting laser sensor data. When the laser detects an object, all points along the line between the sensor and the detected object are marked as unoccupied. This marking must be done carefully to avoid too much interference with cells already marked as occupied, that is, the biggest the chance of it being occupied, the lesser the impact of the inverse sensor model on it. The last point on the line is excluded from the unoccupied cells as it's the detected point.

<p align="center">
<img width="395" alt="Screenshot 2024-07-15 at 10 04 23" src="https://github.com/user-attachments/assets/c09591e9-b5dd-480d-94d8-88000884b027">
<p/>


### Grid making
Takes each point returned by the Inverse Sensor Model and mark those as unoccupied, with the considerations of not influencing occupied cells as much. 

Take each point marked as occupied by the sensor, translate those to the world coordinate system and update each cell with the same coordinates as the given occupied cells. 

The order of this operations is important. As we want to avoid marking occupied cells as unoccupied with the Inverse Sensor Model. 

### Grid reduction
Simplifies the grid for the navigation strategy. 

1. Cells with a value less than 0.2 are marked as unoccupied(0)
2. Cells with a value greater than 0 are marked as occupied(1)
3. Cells from -0.2 to 0 are marked as unknown(2)

<p align="center">
<img width="360" alt="Screenshot 2024-07-13 at 23 07 45" src="https://github.com/user-attachments/assets/1d71e942-e9e3-4671-a479-88c66ea26708">
<img width="360" alt="Screenshot 2024-07-13 at 23 07 57" src="https://github.com/user-attachments/assets/05d2f6b4-1203-4e58-90bb-9f1d719b5165">
<p/>
<p align="center">
Normal grid on the left, reduced on the right
<p/>
  
With better sensors and algorithms, the interval of the unknown could be expanded, as to make the robot visit places where the confidence of the reading is as high.

### Padding 
For finding the path for the robot to follow in the grid, it's needed to consider the size of the robot, to do so, padding around the 1s on the reduced matrix should be added. Paddings of different forms were tested, but the best one proves to be the square. 

The padding should vary depending on the robot size and the cell size, the smaller the cell, the bigger the padding(robot size / cell size) + margin of safety.

<p align="center">
<img width="360" alt="Screenshot 2024-07-13 at 23 08 08" src="https://github.com/user-attachments/assets/157be9fd-b46d-4a97-8660-d092fc9beb20">
<img width="355" alt="Screenshot 2024-07-13 at 23 07 57" src="https://github.com/user-attachments/assets/4a1c61b9-c49c-4558-bd46-e0b7f7b5f0b7">
<p/>
<p align="center">
Padded on the left, not paddeed on the right
<p/>

## Frontier Detection and Operations 
Finding edges and extracting those regions from the grid.

Edges/Frontiers are the cells that have a neighbor that is unknown(2s). When the Frontier has a Frontier neighbor, it should be considered the same frontier

### Frontier Detection
Using the ternary simplified grid of 0s, 1s and 2s, Iterating through the whole grid, for each cell. If it is a 0(unoccupied) and has a 2(unknown) neighbor, it should me marked and 1 on the Frontier grid, else, it's a 0.

The resulting grid is the Frontier grid. With ones being the Frontiers and 0s the non Frontiers.

<p align="center">
<img width="701" alt="Screenshot 2024-07-14 at 18 07 13" src="https://github.com/user-attachments/assets/679508f3-78cb-46d4-9ffd-3e33cbcfdfa1">

<p/>

## Best Frontiers Search
"Best frontiers" is relative. But two possible hypotheses are: the biggest, and the closest, considering a minimum size. A middle point between these two hypotheses could be found too, as it's normally not so close to obstacles and bring more new information, but when the frontiers are too big, going to the center point, and not the closest one, might not be a good choice.

A minimum size of component should be taken in consideration, as in a small cell grid, one unknown cell might not bee a considerable area. 

### Biggest Frontier Search
Finding the biggest frontier with a process analogous to edge detection and region extraction in computer vision, as suggested by Brian Yamauchi.

The steps are:

1. The scipy library is used to find and label the connected components in the graph(matrix), that is, all the ones with at least one 1 as a neighbor.
2. Find the sizes of each connected component 
3. With the connected components labeled and their sizes, find the label of the biggest one and if it's bigger than the minimum size.
4. Find every point on the component
5. Finally, two alternatives are possible:
- Finding the centroid of the connected component 
- Finding the closest point of the connected component 

### Closest Frontier Search
Very similar to the above on, but after finding the connected components, and filtering the considerable size ones, take the centroid or the closest point of it. 

## Best path to the best frontier using A*
This is very similar to Dijkstra’s algorithm, but includes heuristics to optimize the pathfinding process(we choose the best next step based on the heuristic). The heuristics make the process of estimating the cost to reach the goal better, so it's a smarter choice what point to explore next. It's important to note that the heuristic can ruin the algorithm if it makes a worst distance estimation. It can't overestimate distances, it's better to use an absurd heuristic than one that overestimate distances. That why we cant use the Manhattan distance in the case of diagonally abled moves, as it's used in the program. 

A* uses the actual distance from the start and the estimated distance to the goal(based on the heuristic) to find the best path to the objective

In this program early exit is implemented too. So if a point's neighbor is the goal, we finish the algorithm, as it makes the path finding way faster. 

The idea is to tie each point to a cost to the goal(based on the heuristic), a cost from the start and from which point it came from. For each point, from the starting one, we visit all neighbors, for each one of them we check if they are the goal, if not we update its current cost from the start to the current cost(from the start to were we are + from where we are to this neighbor) If this cost is smaller then the neighbor's current one, than we tie this new_cost to this point and put it in the priority queue.
We follow this logic taking the first value of the priority queue(is always the point with the smaller heuristic + cost so far value). 

The catch of the A* algorithm is mixing the heuristic with the cost so far to get to that point.

Now, in the case of the program, the matrix inputed to the A* is the padded grid, in that way, A* finds the best path avoiding the obstacles and considering the size of the robot itself.

It's worth noting that: 
- Unknown cells are'n considered paths, for obvious reasons that we don't know if there is something there.
- If there isn't a path to the point(as sometimes erros in precision causes frontiers to be found in complicated places) a path to the closest points is searched.

<p align="center">
<img width="699" alt="Screenshot 2024-07-14 at 20 01 45" src="https://github.com/user-attachments/assets/6e47aec1-d215-4819-b05a-44320844a67b">
<p/>
  
## Ramer-Douglas-Peucker Algorithm
With smaller cells, come more granular grids, and so, bigger paths, that is, with more points. A path a 1 meter in a 0.01 cell would have 100! points. It's not possible to pass each of the 100 points to the robot for it to go to, so the Ramer-Douglas-Peucker algorithm is used to simplify it.

The Ramer-Douglas-Peucker (RDP) algorithm is used to simplify a curve or path by reducing the number of points while preserving its overall shape. It works by recursively removing points that are within a certain distance (epsilon) from the line connecting the start and end points of the path segment. The algorithm begins by identifying the point that is farthest from this line, and if this distance is greater than epsilon, that point is kept, and the process is repeated for the segments on either side of this point. If the distance is less than epsilon, the intermediate points are discarded, resulting in a simplified path that closely approximates the original with fewer points. This helps a lot in reducing the number of points, but brings another problem, too few points...

Is's a problem because, if its a big distance, aN error in the angle the robot left the last point can get too big and make it so it doesn't arrive at the next point. 

So adding intermediate points is needed. This function ensures that the distance between consecutive points in a path does not exceed a specified max distance. It does this by adding intermediate points along segments that are longer than max_distance. For each segment, it calculates the number of intermediate points needed and inserts them at evenly spaced intervals between the start and end points. so the robot can follow it step by step.

<p align="center">
<img width="360" alt="Screenshot 2024-07-15 at 10 32 51" src="https://github.com/user-attachments/assets/538e049e-6c5a-4eb1-96b5-be84f6ef8d46">
<img width="360" alt="Screenshot 2024-07-15 at 10 34 13" src="https://github.com/user-attachments/assets/74dedb19-117b-49cd-b7c4-b57d8d3f8608">
<p/>
<p align="center">
Reduced path on right, normal path on right
<p/>

## Exploring function 
**Calculates the padding needed:** The Kobuki has 35cm in diameter, that a 17.5 radius and that's the distance it should be away from objects, but a margin of safety is needed. That's why 30 cm is used, to get the padding formula to 0.3 / cell size.

**Finds the frontier minimum size:** The frontier minimum size is arbitrary and depends on the needs of the moment. But it should be bigger with smaller cells, as a same area is occupied by way more small cells than big cells. If the objective is a minimum area, it should be inversely proportional to the cell size. 

**Makes all grid needed:** The reduced, padded and frontier grids are computed now, before deciding where the robot should go. 

**Decides goal and moves there**
1. Finds the closest frontiers with a minimum size, returning if there isn't one
2. Finds the best path to this frontier
3. Simplfies the path with the Ramer-Douglas-Peucker Algorithm
4. Adds intermidiatte pointes to help robot navigation 
5. If path to the closest isn't found or had some trouble, tries the biggest frontier and do the same path modifications
6. Follows the path point by point with the movement functions
7. Keeps checkin sensor readings for being too close to obstacles, if its too close, it stops and tries the go back n moves, that's 0.5m with the function adding intermediate points between 0.05m.
8. When arriving at the goal. do a 360 to gater information. 

## The class OccupancyGrid

**It takes as atributes:**
- Size of the x dimension of the map in meters(default is 10).
- Size of the y dimension of the map in meters(default is 10).
- The size of each cell in the grid, determining the grid’s resolution.
- The handle of the sensor used to get its position.
- The handle of the robot.
- The handle for the left motor of the robot.
- The handle for the right motor of the robot.
- The velocity of the robot.
- A 2D numpy array representing the occupancy grid.
- The confidence level of the sensor’s readings (probability of occupancy given the sensor reading).

And it creates the grid(not the map grid defined by x and y) with the dimension of the map/cell size, filled with zeros(unknown in log odds log(1) = 0)

**Update**
Updates the grid with new probabilities based on the latest sensor measurements. This involves:

1. Converting sensor data to world coordinates.
2. Translating sensor and occupied cell coordinates.
3. Identifying unoccupied cells and updating their probabilities in the grid.
4. Updating the grid with occupied cell probabilities based on the sensor’s confidence.

**Returns the current grid** `get_grid`
returns the grid for external usage

**Plots the path** `plot_path`
If you give this function the points path, it plots on the grid.

**Plots in general**
`plot_grid_var(self, probability_grid_plot=False, reduced_grid_plot=False, padded_grid_plot=False, frontiers_grid_plot=False)`
Plots various versions of the grid based on the specified parameters:

`probability_grid_plot`: Plots the grid showing probabilities of occupancy.
`reduced_grid_plot`: Plots the simplified grid with reduced values.
`padded_grid_plot`: Plots the grid with padding around occupied cells.
`frontiers_grid_plot`: Plots the grid showing detected frontiers (edges between known and unknown areas).


## 5. Tests
Some tests registered

For every case that changing variables didn't allow the robot to finish because the design of the map(chair, table and shelf), the fixed map was used. And it drastically changes the performance of the algorithm, as it doesnt depend os luck to avoid those obstacles and dwelves into a diferent set of paths:
Here are the follwing paths of the fized map:

<p align="center">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 17" src="https://github.com/user-attachments/assets/9526f145-cb1f-4c9d-9096-f64a916be06b">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 23" src="https://github.com/user-attachments/assets/f3071d81-0fac-45fe-a029-9387bed866a0">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 31" src="https://github.com/user-attachments/assets/6f5b32fe-46a5-4db6-9c6e-356e0d134641">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 38" src="https://github.com/user-attachments/assets/3b2154bc-a0ff-47cc-b42c-2138f1b5328b">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 44" src="https://github.com/user-attachments/assets/fd7b58f7-b668-4d1e-b685-b6863e43cf27">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 51" src="https://github.com/user-attachments/assets/ce641ae0-83e6-4112-b60d-48eefd9bb79a">
<img width="360" alt="Screenshot 2024-07-15 at 04 33 59" src="https://github.com/user-attachments/assets/a4bb1d58-d34b-4b2a-8ce3-87e3a6fb35c0">
<img width="360" alt="Screenshot 2024-07-15 at 04 34 09" src="https://github.com/user-attachments/assets/7295b80c-233f-4578-b647-942d912fbedd">
<p/>

**First, with the static map** 

An example of a path made, on a 0.01 cell grid.



Cell size without sensor noise, 0.99 sensor precision and low velocity(1ms)

<img width="701" alt="Screenshot 2024-07-15 at 03 34 33" src="https://github.com/user-attachments/assets/d358f5e3-b5ba-4612-9c7b-7ba8b0dbbb49">
<p align="center">
0.01m cell size
<p/>

0.05m <img width="704" alt="Screenshot 2024-07-15 at 04 34 09" src="https://github.com/user-attachments/assets/a1d0d981-5689-409a-be52-20ed7714e179">
<p align="center">
0.05 cell size
<p/>

0.1m y

<p align="center">
<img width="691" alt="Screenshot 2024-07-15 at 05 51 31" src="https://github.com/user-attachments/assets/2c331d1f-fbee-4c66-9168-d373f8b43b67">
<p/>
<p align="center">
0.5 cell size: Unusable
<p/>

with sensor noises

<p align="center">
<img width="704" alt="Screenshot 2024-07-15 at 06 06 54" src="https://github.com/user-attachments/assets/6e4b84f6-9e19-46c9-8500-3ba2efb24c9e">
<p/>
<p align="center">
sensor noises this high make really small sizes very bad
<p/>


<p align="center">
<img width="700" alt="noisy_005m" src="https://github.com/user-attachments/assets/90ec5360-afc7-4b7f-8c06-15e8b1fe4601">
<p/>
<p align="center">
0.05 cell size
<p/>
0.1m

bigger noise 

0.05m

0.1m

dynamic map:

0.05

0.1

dynamic map with noise


0.05

0.1




## 6. Conclusion

- In simpler maps, Frontier Based algorithms can be very efficient in exploring them, even tho, as the cell size grows, the computation needed for calculating the path to a distant frontier, like when the robot goes one way just to arrive at the end and have to go back to a frontier at the beginning. But this is realizable just after the map is built, when there is no information about the map, this strategy is very efficient.
  
- Gathering information is really important, that's why the speed of the 360 can impact so much. If a small object is undetected or overwritten, it can make the path making algorithm design a horrible path that ruins the run.

- The idea of moving to a frontier is great because it's a region with a high probability of bringing a lot of new information. But when a frontier is smaller than the robot, which is a good minimum size, as the robot wont be able to fit in a space smaller for exploring, a problem shows, it isn't a good algorithm fot discovering small details or looking through a small hole to see what behind it, for example.

- When obstacles are very close to to the frontier, it can be a problem, thats when a good reactiveness of the robot is usefull. It can't just depend on the planning.

- The speed of the robot can influence the mapping a lot. A very good reading asks for a slow moving robot, specially with a no state of the art sensor. But for not so great mapping, the speeds can be higher, as the doesn't fall too much with higher speed, with a stable robot like Kobuki.

- Small objectes can be trouble for the robot, specially with big cells, as the inverse sensor model can mark them as unoccupied.

- It's possible to push the limits of speed more when you do recognition more slowly. If a fixed speed is set for the 360, to the a very slow and good analysis, the pathing becomes way better and, sometimes, that's the only way to do it at that speed, as rotations made too fast can break the map.

- If the velocity needs to be high, small cells won't work. Opt for bigger cells. Like in the case of dynamic maps. You can't stay on the same place for much time and need to react fast. Combining both is ideal, that is, moving slowing until you find dynamic targets, but in the case studied, even with faster reaction thet kobuki wasn't able to leave the way of the human. And if the "too close" distance is set to be too big, it willstop at too much obstacles or not allow the pathing between close ones, as it can't differentiate a dynamic and a static obstacle. 

- If the too close range is too small, it can cause trouble to the robot and make it stuck. In this case, a better strategy of navigation, with a better design of the reactive part would be needed.

- In pratice, various elements can be ran at the same time, making it easier for the robot to update the grid and move at the same time. To do that in simulation enviroments ir more complicated.

- Depending on the readings, one can get unlucky or lucky. It's one occupied cell between two connected componentes that can make it not the biggest one and send to robot to a path totally different, that could be way better or way worse.

- On the computation side, small cells can be very impactful, first, for storing all the grids, secondly, for the pathing algorithm, as its `O(V)` in space, but `O(Elog(V))` performance, both when with the best heuristic, that can still take a lot of time if the desired point isn't found and closer vertices have the be analyzed.

- Given all that, the best cell size used was 0.05, allowing for the robot to deal with a dynamic environment while still mapping with good quality and not taking too much time with computation.

- But for a clear an quality mapping, even tho slower, the 0.01 cell size gave the best results, even tho it can cause some problem with the mapping as unoccupied cells can me marked as occupied because the sensor didn't have a high resolution to get the cell and it ended up between two laser beans.

- 0.1 is a good number too, being quicker, but here the loss of quality starts to become more clear.

- 0.5 is unusable, specially for the detailed environment and robot size. It blocks paths otherwise open and messes up with the readings, as the sensor has too much detail for such big cell sizes, maybe a less detailed sensor would be more optimal for such big cells. 

## 7. Bibliography

[A* algorithm, Stanford article](https://theory.stanford.edu/~amitp/GameProgramming/AStarComparison.html)
[Coppelia Manual](https://manual.coppeliarobotics.com/en/apiFunctions.htm)

[Conditional Bayes article](https://dzone.com/articles/conditional-probability-and-bayes-theorem)

[Numpy reference guide(documentation)](https://numpy.org/devdocs/reference/index.html#reference)

["A Frontier-Based Approach for Autonomous Exploration" ,Brian Yamauchi, Navy Center for Applied Research in Artificial Intelligence, Naval Research Laboratory](https://faculty.iiit.ac.in/~mkrishna/YamauchiFrontier.pdf)

MODERN ROBOTICS MECHANICS, PLANNING, AND CONTROL, Kevin M. Lynch and Frank C. Park

Probabilistic ROBOTICS, SEBASTIAN THRUN WOLFRAM BURGARD DIETER FOX

[A Comparison of Path Planning Strategies for Autonomous Exploration and Mapping of Unknown Environments, 
Miguel Juli ́a and Arturo Gil and Oscar Reinoso](https://www.researchgate.net/publication/228068408_A_Comparison_of_Path_Planning_Strategies_for_Autonomous_Exploration_and_Mapping_of_Unknown_Environments)
