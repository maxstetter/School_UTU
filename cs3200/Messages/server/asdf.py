from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
import json
from urllib.parse import parse_qs
from dummydb import DummyDB
#need to replace array with a saved text file.
RESTAURANTS = ["red lobster", "red robin", "red fort"]


class MyRequestHandler( BaseHTTPRequestHandler ):
   
    #this is DJ's example end_headers
    def end_headers(self):
        #send common headers
        self.send_header("Access-Control-Allow-Origin","*")
        
        #call the ORIGINAL end_headers()
        super().end_headers()

    def handleRetrieveRestaurants(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        db = DummyDB('mydatabase.db')
        restaurants = db.readAllRecords()
        self.wfile.write(bytes(json.dumps(restaurants), "utf-8"))
    
    def handleRetrieveRestaurant(self, id):
        #make sure to allow for a 404 error if it doesnt exist
        car = db.getOneCar.getOneCar(id)

        if car != None:
            self.send_response(200)
            self.send_header( "Content-Type", "application/json" )
            self.end_headers()
            self.wfile.write( bytes(json.dumps(car), "utf-8" ))
        else:
            self.handleNotFound()


    def handleCreateRestaurant(self):
        #1. read the incoming body request
        length = int(self.headers["Content-Length"])
        request_body = self.rfile.read(length).decode("utf-8")
        print("raw request body: ", request_body)
        
        #2. parse the request body (urlencoded data)
        parsed_body = parse_qs(request_body)
        print("parsed request body: ", parsed_body)

        #3. retrieve restaurant data from the parsed body.
        restaurant_name = parsed_body['name'][0]

        #4. append the restaurant to the array above.
        db = DummyDB('mydatabase.db')
        #when done replace RESTAURANTS.append with 
        db.saveRecord(restaurant_name)
        #RESTAURANTS.append(restaurant_name)

        self.send_response(201)
        #headers go here, if any
        self.send_header( "Content-Type", "application/json" )
        self.end_headers()
        #body goes here, if any
        self.wfile.write(bytes("Created", "utf-8"))

    def handleNotFound(self):
        self.send_response(404)
        #headers go here, if any
        self.send_header( "Content-Type", "text/plain" )
        self.end_headers()
        #body goes here, if any
        self.wfile.write(bytes("Not Found :c ", "utf-8"))
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self):
        #what are the ingredients for an HTTP response?
        #status code(required), headers (optional), body (optional)
        
        if self.path == "/cars":
            self.handleCreateRestaurant()

        else:
            self.handleNotFound()

    def do_GET(self):
        #what are the ingredients for an HTTP response?
        #status code(required), headers (optional), body (optional)
        
        print("the request path is: ", self.path)
        parts = self.path.split( "/" )
        
        collection = parts[1]
        if len(parts) > 2:
            member_id = parts[2]

        if collection == "cars":
            if member_id:
                self.handleRetrieveRestaurant( member_id )
            else:
                self. handleRetrieveRestaurants()
        else:
            self.handleNotFound()

#update is basically create mixed with delete


#        if self.path == "/cars":
#            self.handleRetrieveRestaurants()

#        elif self.path == member_id:
#            self.handleRetrieveRestaurants()

#        else:
#            self.handleNotFound()


class ThreadedHTTPServer( ThreadingMixIn, HTTPServer ):
    pass


def main():
    #start the server
	
    listen = ("127.0.0.1", 8080)
    server = ThreadedHTTPServer( listen, MyRequestHandler )
    print("Listening: ", listen)
    print("The server is running")
    server.serve_forever()
    print("hello")
main()
