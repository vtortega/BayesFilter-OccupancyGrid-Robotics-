sim=require'sim'

function sysCall_init()
    -- do some initialization here
    h=sim.getObject("/kobuki")
    dr=sim.addDrawingObject(sim.drawing_lines|sim.drawing_cyclic,5,0,-1,1000,{1,1,0})
    pt=sim.getObjectPosition(h,-1)
end

function sysCall_actuation()
    -- put your actuation code here
end

function sysCall_sensing()
    -- put your sensing code here
    local l={pt[1],pt[2],pt[3]}
    pt=sim.getObjectPosition(h,-1)
    l[4]=pt[1]
    l[5]=pt[2]
    l[6]=pt[3]
    sim.addDrawingObjectItem(dr,l)
end

function sysCall_cleanup()
    -- do some clean-up here
end

-- See the user manual or the available code snippets for additional callback functions and details
