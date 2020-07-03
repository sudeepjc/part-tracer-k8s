const express = require("express");
const Joi = require('joi');
const enrollUser = require('./app/enrollUser');
const addPart = require('./app/addPart');
const sellPart = require('./app/sellPart');
const queryPart = require('./app/query');
const getChannelInfo = require('./app/getChannelInfo');
const getPeerInfo = require('./app/peerQuery');

const app = express();
app.use(express.json());

app.post('/api/:org/enroll/:user', async (req,res)=>{

    const schema = Joi.object({
        userPwd: Joi.string().min(3).required(),
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(req.params.org != 'general'){
        return res.status(400).send("This request was meant for general organization");
    }

    if(!req.params.user && req.params.user.length >3 ){
        return res.status(400).send("Input validation error w.r.t user");
    }

    let response = await enrollUser(req.params.user,req.body.userPwd,req.params.org);
    if(response && response.success){

        console.log(`Enroll was Success: ${response.message}`);

        res.status(201).json(response);
    }else{
        console.log(`Enroll was Failure: ${response.message}`);
        res.status(401).json(response);
    }
});

app.post('/api/:network/:chaincode/part', async (req,res)=>{

    const schema = Joi.object({
        user: Joi.string().min(3).required(),
        partDetails : Joi.array().items(Joi.string().min(3).required(),Joi.string().min(3).required(),Joi.string().min(3).required(),Joi.string().min(3).required(),Joi.string().min(3).required()),
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(!req.params.network && req.params.network.length() <= 0){
        return res.status(400).send("This request was sent to a bad network ");
    }

    if(!req.params.chaincode && req.params.chaincode.length() <= 0){
        return res.status(400).send("This request was sent to a bad chaincode ");
    }

    let response = await addPart(req.body.user,req.params.network,req.params.chaincode,req.body.partDetails);
    if(response && response.success){

        console.log(`Addpart was Success: ${response.message}`);

        res.status(201).json(response);
    }else{
        console.log(`Addpart was Failure: ${response.message}`);
        res.status(parseInt(response.status)).json(response);
    }

});

app.put('/api/:network/:chaincode/sell/part', async (req,res)=>{

    const schema = Joi.object({
        user: Joi.string().min(3).required(),
        partDetails : Joi.array().items(Joi.string().min(3).required(),Joi.string().min(3).required(),Joi.string().min(2).required()),
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(!req.params.network && req.params.network.length() <= 0){
        return res.status(400).send("This request was sent to a bad network ");
    }

    if(!req.params.chaincode && req.params.chaincode.length() <= 0){
        return res.status(400).send("This request was sent to a bad chaincode ");
    }

    let response = await sellPart(req.body.user,req.params.network,req.params.chaincode,req.body.partDetails);
    if(response && response.success){

        console.log(`Sellpart was Success: ${response.message}`);

        res.status(201).json(response);
    }else{
        console.log(`Sellpart was Failure: ${response.message}`);
        res.status(parseInt(response.status)).json(response);
    }

});

app.get('/api/:network/:chaincode/parts', async (req,res)=>{

    const schema = Joi.object({
        user: Joi.string().min(3).required(),
        function : Joi.string().min(3).required(),
        queryArgs : Joi.array().min(1),
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(!req.params.network && req.params.network.length() <= 0){
        return res.status(400).send("This request was sent to a bad network ");
    }

    if(!req.params.chaincode && req.params.chaincode.length() <= 0){
        return res.status(400).send("This request was sent to a bad chaincode ");
    }

    let response = await queryPart(req.body.user,req.params.network,req.params.chaincode, req.body.function,req.body.queryArgs);

    if(response && response.success){

        console.log(`Query was Success: ${response}`);
        res.status(200).json(response.queryResult);

    }else{
        console.log(`Query was Failure: ${response.message}`);
        res.status(500).json(response.message);
    }
});

app.get('/api/channel/:channelName', async (req,res)=>{

    const schema = Joi.object({
        user: Joi.string().min(3).required(),
        org : Joi.string().min(3).required()
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(!req.params.channelName && req.params.channelName.length() <= 0){
        return res.status(400).send("This request was sent to a bad chaincode ");
    }

    let response = await getChannelInfo(req.body.user,req.body.org,req.params.channelName);

    if(response && response.success){

        console.log(`Query was Success: ${response}`);
        res.status(200).json(response);

    }else{
        console.log(`Query was Failure: ${response.message}`);
        res.status(500).json(response.message);
    }
});

app.get('/api/peers/:peerName', async (req,res)=>{

    const schema = Joi.object({
        user: Joi.string().min(3).required(),
        org : Joi.string().min(3).required()
    });
    
    const result = schema.validate(req.body);
    
    console.log(result);
    
    if (result.error) {
        return res.status(400).send(result.error);
    }

    if(!req.params.peerName && req.params.peerName.length() <= 0){
        return res.status(400).send("This request was sent to a bad chaincode ");
    }

    let response = await getPeerInfo(req.body.user,req.body.org,req.params.peerName);

    if(response && response.success){

        console.log(`Query was Success: ${response}`);
        res.status(200).json(response);

    }else{
        console.log(`Query was Failure: ${response}`);
        res.status(500).json(response);
    }
});

let port = process.env.PORT || 3000;
app.listen(port, () => console.log(`listening on port ${port}....`));