import os
import sys
import numpy as np
from plantcv import plantcv as pcv
import argparse
import cv2
from pyzbar import pyzbar

# Function for parsing command line options using argparse
def options():
    parser = argparse.ArgumentParser(description="Imaging processing with PlantCV.")
    parser.add_argument("-i", "--image", help="Input image file.", required=True)
    parser.add_argument("-r","--result", help="Result file.", required= True )
    parser.add_argument("-o", "--outdir", help="Output directory for image files.", required=False)
    parser.add_argument("-w","--writeimg", help="Write out images.", default=False, action="store_true")
    parser.add_argument("-D", "--debug", help="Turn on debug, prints intermediate images.")
    args = parser.parse_args()
    return args

def main():
    # Gets the values of the command-line options
    args = options()

    # Set variables
    pcv.params.debug = args.debug

    # Read image
    img, path, filename = pcv.readimage(filename=args.image)

    capture = filename.split("-", 2) #use _ for cryogenics photos
    
    # Processes photos from top-view cameras (2 and 3)
    if (capture[1] == "2") or (capture[1] == "3"):

        a = pcv.rgb2gray_lab(rgb_img=img, channel='a')

        img_binary = pcv.threshold.binary(gray_img=a, threshold=119, max_value=255, object_type='dark')

        fill_image = pcv.fill(bin_img=img_binary, size=1000)

        id_objects, obj_hierarchy = pcv.find_objects(img=img, mask=fill_image)

        #For cryogenics camera 2 and later photos, uncomment:
        #rois1, roi_hierarchy1 = pcv.roi.multi(img=img, coord=[(1150,800), (2000,800), (2900, 800)], radius=350)

        #For early cryogenics camera 3, uncomment:
        #rois1, roi_hierarchy1 = pcv.roi.multi(img=img, coord=[(1100,1050), (2000,1000), (2900, 1000)], radius=350)

        #For new/smaller image size, uncomment:
        rois1, roi_hierarchy1 = pcv.roi.multi(img=img, coord=[(500,550), (1000,550), (1500, 550)], radius=210)

        img_copy = np.copy(img)

        for i in range(0, len(rois1)):
            roi_objects, roi_obj_hierarchy, kept_mask, obj_area = pcv.roi_objects(img=img, roi_contour=rois1[i], roi_hierarchy=roi_hierarchy1[i], object_contour=id_objects, obj_hierarchy=obj_hierarchy, roi_type='partial')
            
            pcv.params.debug = "none"
            if len(roi_objects) > 0:

                filtered_contours, filtered_hierarchy, filtered_mask, filtered_area = pcv.roi_objects(
                    img=img, roi_type="partial", roi_contour=rois1[i], roi_hierarchy=roi_hierarchy1[i], object_contour=roi_objects, 
                    obj_hierarchy=roi_obj_hierarchy)   
            
                plant_contour, plant_mask = pcv.object_composition(img=img_copy, contours=filtered_contours, hierarchy=filtered_hierarchy) 
           
                analysis_image = pcv.analyze_object(img=img_copy, obj=plant_contour, mask=plant_mask, label=str(i))     
            else:
                print("No plant detected.")
                pcv.outputs.add_observation(sample=str(i),method= "pcv.analyze_object", variable="area",trait="area",scale="Pixels",datatype=int,value=0, label="area")

            pcv.outputs.save_results(filename=args.result, outformat="json")
        
            
    # Processes images from side-view cameras (1 and 4)
    if (capture[1] == "1") or (capture[1] == "4"):

        # Rotate image
        rotate_img = pcv.transform.rotate(img=img, rotation_deg=-90, crop=False)

        # Convert to grayscale (green-magenta channel)
        a = pcv.rgb2gray_lab(rgb_img=rotate_img, channel='a')

        # Create image mask
        img_binary = pcv.threshold.binary(gray_img=a, threshold=123, max_value=255, object_type='dark')

        # Fill in small objects (speckles)
        fill_image = pcv.fill(bin_img=img_binary, size=1000)

        # Find objects (contours: black-white boundaries)
        id_objects, obj_hierarchy = pcv.find_objects(img=rotate_img, mask=fill_image)

        # Loop to create a ROI and analyze the object within it for each of the 3 tubes
        img_copy = np.copy(rotate_img)

        for i in range(3):
            pcv.params.debug = "print"
            
            # Barcode detection
            if i == 0:
                    cropped_image = img[950:1500, 0:1000]
                    rotated = pcv.transform.rotate(img=cropped_image, rotation_deg=5, crop=False)
            if i == 1:
                    cropped_image = img[450:950, 0:1000]
                    rotated = pcv.transform.rotate(img=cropped_image, rotation_deg=1, crop=False)   
            if i == 2:
                    cropped_image = img[0:600, 0:1000]
                    rotated = pcv.transform.rotate(img=cropped_image, rotation_deg=-5, crop=False)

            hsv = pcv.rgb2gray_hsv(rotated, channel='v')

            for t in range(100,200):
                binary = pcv.threshold.binary(hsv, threshold=t, max_value=255, object_type='light')
                barcodes = pyzbar.decode(binary)
                if len(barcodes)==1:
                        break
            
            for barcode in barcodes:
                    barcodeData = barcode.data.decode("utf-8")
                    pcv.outputs.add_observation(sample=str(i),method= "pyzbar", variable="Barcode",trait="Barcode",scale="String",datatype=str,value=barcodeData, label="Barcode")

            # Image analysis
            xvalue = [100,570,1100]
            roi_contour, roi_hierarchy = pcv.roi.rectangle(img=rotate_img, x=xvalue[i], y=850, h=800, w=400)

            roi_objects, roi_obj_hierarchy, kept_mask, obj_area = pcv.roi_objects(img=rotate_img, roi_contour=roi_contour, 
                                                                            roi_hierarchy=roi_hierarchy,
                                                                            object_contour=id_objects, 
                                                                            obj_hierarchy=obj_hierarchy, 
                                                                            roi_type='partial')
            pcv.params.debug = "none"
            if len(roi_objects) > 0:
                row_list = []
                column_start_value = [100,570,1100]
                column_end_value = [500,970,1500]
                
                filtered_contours, filtered_hierarchy, filtered_mask, filtered_area = pcv.roi_objects(
                img=img_copy, roi_type="partial", roi_contour=roi_contour, roi_hierarchy=roi_hierarchy, object_contour=roi_objects, 
                obj_hierarchy=roi_obj_hierarchy)
                
                plant_contour, plant_mask = pcv.object_composition(img=img_copy, contours=filtered_contours, hierarchy=filtered_hierarchy) 

                img_copy = pcv.analyze_object(img=img_copy, obj=plant_contour, mask=plant_mask, label=str(i)) 

                # Calculating height
                for row in range(0,800): # 800 rows = height of ROI
                        row_elements = plant_mask[850 + row, column_start_value[i]:column_end_value[i]] # array of elements in the row within the ROI
                        row_sum = np.sum(row_elements) # sum of the elements in that row

                        if row_sum > 30000:
                                row_list.append(row)

                height = len(row_list)
                pcv.outputs.add_observation(sample=str(i),method= "binary image", variable="Height",trait="Height",scale="Pixels",datatype=int,value=height, label="Height")
            else:
                print("No plant detected.")
                pcv.outputs.add_observation(sample=str(i),method= "pcv.analyze_object", variable="area",trait="area",scale="Pixels",datatype=int,value=0, label="area")

            pcv.outputs.save_results(filename=args.result, outformat="json")       
    


if __name__== '__main__':
    main()
