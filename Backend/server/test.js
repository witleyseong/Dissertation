const {calculateExposure} = require("./services/exposureService");

async function run(){
    const leg = [
        [-0.1300, 51.5130],
        [-0.1290, 51.5130],
        [-0.1280, 51.5130],
    ];

    const result = await calculateExposure(leg,50);
    console.log("result:",result);
    process.exit(0)
}

run();