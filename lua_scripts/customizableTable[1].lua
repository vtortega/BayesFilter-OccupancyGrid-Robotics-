sim=require'sim'

function sysCall_init()
    local tableConfig={}
    tableConfig.length=1.4
    tableConfig.width=0.8
    tableConfig.height=0.7
    tableConfig.color1={0.8,0.73,0.7}
    tableConfig.color2={0.57,0.47,0.47}
    
    local model=sim.getObject('/customizableTable[1]')
    local xJoint=sim.getObject('./customizableTable_xJoint1')
    local yJoint=sim.getObject('./customizableTable_yJoint1')
    local tableTop=sim.getObject('./customizableTable_top')
    local tableP=sim.getObject('./customizableTable_table')
    
    local p=sim.getObjectPosition(model,-1)
    sim.setObjectPosition(model,-1,{p[1],p[2],tableConfig.height})
    sim.setShapeBB(tableP,{tableConfig.length,tableConfig.width,0.1})
    sim.setShapeColor(tableP,'',sim.colorcomponent_ambient_diffuse,tableConfig.color2)
    sim.setObjectPosition(tableP,model,{0,0,-0.05})
    sim.setShapeBB(tableTop,{tableConfig.length-0.005,tableConfig.width-0.005,0.1})
    sim.setShapeColor(tableTop,'',sim.colorcomponent_ambient_diffuse,tableConfig.color1)
    sim.setObjectPosition(tableTop,model,{0,0,-0.045})
    for i=1,4,1 do
        local foot=sim.getObject('./customizableTable_foot'..i)
        sim.setShapeBB(foot,{0.055,0.055,tableConfig.height-0.05})
        sim.setShapeColor(foot,'',sim.colorcomponent_ambient_diffuse,tableConfig.color2)
        p=sim.getObjectPosition(foot,model)
        sim.setObjectPosition(foot,model,{p[1],p[2],-0.05-(tableConfig.height-0.05)/2})
    end
    sim.setJointPosition(xJoint,tableConfig.length/2-0.07)
    sim.setJointPosition(yJoint,tableConfig.width/2-0.07)
end
