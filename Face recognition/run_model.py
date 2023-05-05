from imutils.video import VideoStream
from imutils.video import FPS
import numpy as np
import imutils
import time
import cv2
import tensorflow as tf
import serial
from serial import *
from threading import Thread
import io
import re
import face_recognition
from google.cloud import firestore
from google.oauth2 import service_account

delay = 100
time_scan = 10
last_received = ''
recognised = 0
state = 0
count = 0
credentials = service_account.Credentials.from_service_account_file('luminous-shadow-334212-4fcb1265d7f1.json')
db = firestore.Client(credentials=credentials)

doc_ref = db.collection('metadata').document('faces')
doc = doc_ref.get()
if doc.exists:
    faceVectors = doc.to_dict()
else:
    print('No such document!')

interpreter = tf.lite.Interpreter(model_path="facenet_512.tflite")

def print_to_Arduino(ser):
  global recognised
  while True:
      for i in range((time_scan*delay)//1000):
        ser.write(recognised)
        time.sleep(delay/1000)

def euclidean_distance(a, b):
     return np.sqrt(np.sum(np.array(a)-np.array(b))**2)

def cosine_distance(a, b):
    a1 = np.squeeze(np.asarray(a))
    b1 = np.squeeze(np.asarray(b))
    return 1 - (a1.dot(b1) / (np.linalg.norm(a1) * np.linalg.norm(b1)))  # sure??

def receiving(ser):
    global last_received
    global count
    buffer_string = ''
    while True:
        buffer_string = buffer_string + ser.read(ser.inWaiting()).decode()
        if '\n' in buffer_string:
            lines = buffer_string.split('\n') # Guaranteed to have at least 2 entries
            last_received = lines[-2]
            #If the Arduino sends lots of empty lines, you'll lose the
            #last filled line, so you could make the above statement conditional
            #like so: if lines[-2]: last_received = lines[-2]
            buffer_string = lines[-1]

        print(count)
        print(last_received)
        if last_received == "Entry":
          count+=1
          print(count)
          print(last_received)
        elif last_received == "Exit":
          count-=1
          print(count)
          print(last_received)
        elif last_received == "Intruder entry detected!":
          count+=1
          print(last_received)
        elif last_received.startswith("Arduino read: "):
          print(last_received)


# initialize the video stream and allow the camera sensor to warm up
# Set the ser to the followng
# src = 0 : for the build in single web cam, could be your laptop webcam
# src = 2 : I had to set it to 2 inorder to use the USB webcam attached to my laptop
vs = VideoStream(src=1,framerate=10).start()
#vs = VideoStream(usePiCamera=True).start()
time.sleep(2.0)

# start the FPS counter
fps = FPS().start()
# loop over frames from the video file stream


with Serial(port='COM5', baudrate=115200, timeout=0.1) as ser:
  Thread(target=receiving, args=(ser,)).start()
  Thread(target=print_to_Arduino, args=(ser,)).start()
  while True:
    # grab the frame from the threaded video stream and resize it
    # to 500px (to speedup processing)
    frame1 = vs.read()
    frame1 = imutils.resize(frame1, width=500)
    cv2.imshow("Facial recognition is running", frame1)
    key = cv2.waitKey(1) & 0xFF
    if key == ord("a"):
          frame = vs.read()
          frame = imutils.resize(frame, width=500)
          boxes = face_recognition.face_locations(frame)
          print(boxes)
          if(len(boxes) > 0):
            (t, r, b, l) = boxes[0]
            cropped_img = frame[t:b, l:r]
            final_frame = cv2.resize(cropped_img, (160, 160))
            final_frame = np.expand_dims(final_frame, axis=0)
            final_frame = np.array(final_frame, dtype=np.float32)
            # compute the face vector using mobilefacenet tflite model
            interpreter.allocate_tensors()
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            interpreter.set_tensor(input_details[0]['index'], final_frame)
            interpreter.invoke()
            output_data = interpreter.get_tensor(output_details[0]['index'])
            print(output_data)
            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
              break
            min_distance = float('inf')
            recognised_name = ''
            print('new image')
            threshold = 1000
            for name, vector in faceVectors.items():
              distance = cosine_distance(vector, output_data)
              print(distance)
              if distance < min_distance:
                min_distance = distance
                recognised_name = name
              print(output_data[0])
              print(distance)
            if(min_distance < threshold):
                print(recognised_name)
                print(min_distance)
                recognised = True
                time.sleep(time_scan)
                recognised = False
            else:
                print('Unknown')
                print(min_distance)
                recognised = False

	# find  euclidean distance of all elements in faceVector from output_data
	# and find the index of the minimum distance


	

# 	# loop over the facial embeddings
# 	for encoding in encodings:
# 		# attempt to match each face in the input image to our known
# 		# encodings
# 		matches = 
# 		name = "Unknown" #if face is not recognized, then print Unknown

# 		# check to see if we have found a match
# 			# find the indexes of all matched faces then initialize a
# 			# dictionary to count the total number of times each face
# 			# was matched


# 			# loop over the matched indexes and maintain a count for
# 			# each recognized face face

# 			# determine the recognized face with the largest number
# 			# of votes (note: in the event of an unlikely tie Python
# 			# will select first entry in the dictionary)

# 			#If someone in your dataset is identified, print their name on the screen
# 			if currentname != name:
# 				currentname = name
# 				print(currentname)

# 		# update the list of names
# 		names.append(name)




# 	# quit when 'q' key is pressed
# 	if key == ord("q"):
# 		break

# 	# update the FPS counter
# 	fps.update()

# # stop the timer and display FPS information
# fps.stop()
# print("[INFO] elasped time: {:.2f}".format(fps.elapsed()))
# print("[INFO] approx. FPS: {:.2f}".format(fps.fps()))

# # do a bit of cleanup
# cv2.destroyAllWindows()
# vs.stop()