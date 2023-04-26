from imutils.video import VideoStream
from imutils.video import FPS
import numpy as np
import imutils
import time
import cv2
import tflite_runtime.interpreter as tflite

from google.cloud import firestore
from google.oauth2 import service_account

credentials = service_account.Credentials.from_service_account_file('luminous-shadow-334212-46ebe8083d90.json')
db = firestore.Client(credentials=credentials)

doc_ref = db.collection('faces').document('details')
doc = doc_ref.get()
if doc.exists:
    faceVectors = doc.to_dict()
else:
    print('No such document!')

interpreter = tflite.Interpreter(model_path="mobilefacenet.tflite")

# initialize the video stream and allow the camera sensor to warm up
# Set the ser to the followng
# src = 0 : for the build in single web cam, could be your laptop webcam
# src = 2 : I had to set it to 2 inorder to use the USB webcam attached to my laptop
vs = VideoStream(src=0,framerate=10).start()
#vs = VideoStream(usePiCamera=True).start()
time.sleep(2.0)

# start the FPS counter
fps = FPS().start()
# loop over frames from the video file stream
while True:
	# grab the frame from the threaded video stream and resize it
	# to 500px (to speedup processing)
	frame = vs.read()
	frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
	frame = imutils.resize(frame, (112, 112))
	frame = (frame - 127.5) / 128.0
	frame = np.expand_dims(frame, axis=0)
	frame = tflite.convert_to_tensor(frame, dtype=tflite.float32)
        
	# compute the face vector using mobilefacenet tflite model
	interpreter.allocate_tensors()
	input_details = interpreter.get_input_details()
	output_details = interpreter.get_output_details()
	interpreter.set_tensor(input_details[0]['index'], frame)
	interpreter.invoke()
	output_data = interpreter.get_tensor(output_details[0]['index'])
	# print(output_data)


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
