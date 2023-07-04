#Smart Bus App Server

# To run as server on linux terminal
# uvicorn server:app --port 5000 --reload --host your_ip_address

# To run as server on windows cmd
# python -m uvicorn server:app --port 5000 --reload --host 192.168.1.7
# 192.168.1.6

import cv2  #python -m pip install opencv-python
import pymongo  #python -m pip install pymongo

from pydantic import BaseModel  #python -m pip install pydantic
from fastapi.encoders import jsonable_encoder  #python -m pip install  fastapi
from fastapi.responses import JSONResponse
from fastapi import FastAPI, File, UploadFile, HTTPException
import json
import random
from bson import ObjectId

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

dbClient = pymongo.MongoClient("mongodb://localhost:27017")
Database = dbClient['SmartBusApp']
print("Smart Bus App Database : ",Database)

print("Collections : ",Database.list_collection_names())

Users = Database["Users"]
print("DB Users Variable: ",Users)
Buses = Database["Buses"]
print("DB Buses Variable: ",Buses)

class JSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, ObjectId):
            return str(o)
        return json.JSONEncoder.default(self, o)
        
class SignupVals(BaseModel):
    name: str
    mobile: str
    email: str

class BusVals(BaseModel):
    driver_mobile: str
    bus_name: str
    destination: str
    reg_no: str
    arrival_time: str
    reaching_time: str
    booked_user_count: int
    current_lat: float
    current_long: float
    stops: list

class MobileVals(BaseModel):
    mobile: str

class DestVals(BaseModel):
    destination: str

@app.get("/")
async def Base():
    print("Test page invoked")
    return "Smart Bus App server active"
    
#Create api end points

@app.post("/create_user")
async def create_user(input: SignupVals):
    record = {
        "name":input.name,
        "mobile": input.mobile,
        "email": input.email,
    }
    Users.insert_one(record)
    print("User Signup Successful")
    return "User has been successfully added"

@app.post("/get_otp")
async def get_otp(input: MobileVals):
    print("Recieved Mobile: ",input.mobile)
    result = Users.find_one({"mobile":input.mobile})
    if(result is None):
        return 999
    print("Fetched Student : ",result)
    return random.randint(1000,9999)
    
@app.post("/update_user")
async def update_user(input: SignupVals):
    result = Users.update_one({"mobile":"{input.mobile}"},{"email":"{input.email}", "name":"{input.name}"})
    if(result is None):
        print("User Update Failed")
        return "Failed"
    print("User Update Successful")
    return "Success"

@app.get("/get_user")
async def get_user(input: MobileVals):
    print("Recieved Mobile: ",input.mobile)
    result = Users.find_one({"mobile":input.mobile})
    if(result is None):
        return ""
    print("Fetched Student : ",result)
    return JSONEncoder().encode(result)

@app.post("/create_bus")
async def create_bus(input: BusVals):
    record = {
        "driver_mobile": input.driver_mobile,
        "bus_name": input.bus_name,
        "destination": input.destination,
        "reg_no": input.reg_no,
        "arrival_time": input.arrival_time,
        "reaching_time": input.reaching_time,
        "booked_user_count": input.booked_user_count,
        "current_lat": input.current_lat,
        "current_long": input.current_long,
        "stops": input.stops
    }
    Buses.insert_one(record)
    print("Bus Creation Successful")
    return "Bus has been successfully created"

@app.get("/get_buses")
async def get_buses():
    result = Buses.find()
    if(result is None):
        JSONEncoder().encode({"result":[]})
    finArr = []
    for item in result:
        finArr.append(item)
        print(item)
    return JSONEncoder().encode({"result":finArr})

@app.post("/set_destination")
async def set_destination(input: BusVals):
    result = Buses.update_one({"reg_no":input.reg_no},{"$set":{"booked_user_count": input.booked_user_count, "reaching_time": input.reaching_time, "arrival_time":input.arrival_time, "destination": input.destination, "stops":input.stops}})
    if(result is None):
        print("Updated Bus Destination Failed")
        return "Failed"
    print("Updated Bus Destination :")
    print(result)
    return "Success"
