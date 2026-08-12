import asyncio
import websockets
import json
import sys

async def test_chat():
    uri = "ws://localhost:8000/ws/chat/test_user"
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected!")
            
            # Receive initial history message
            history = await websocket.recv()
            print(f"History: {history[:100]}...")
            
            # Send a test message
            await websocket.send(json.dumps({"message": "Hello, how are you?"}))
            print("Sent message")
            
            # Receive the response
            while True:
                response = await websocket.recv()
                data = json.loads(response)
                print(data)
                if data["type"] == "stream_end":
                    break
                    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_chat())
