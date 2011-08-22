//	Copyright 2010 Boris Shabash, Ghassan Hamarneh, Zhi Feng Huang, and Luis Ibanez
//	
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.


#import "TesViewBasedAppViewController.h"

@implementation TesViewBasedAppViewController

@synthesize imagePicker;

- (void)viewDidLoad {
	image.image = nil;
	image.contentMode = UIViewContentModeScaleAspectFit;
	self.imagePicker = [[UIImagePickerController alloc] init];
	self.imagePicker.delegate = self;
	self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

/*************************************************************************************************************/

- (IBAction)grabImage {
	if (image.image != nil)
	{
		image.image = nil;
		//[image.image release];
	}
	[self presentModalViewController:self.imagePicker animated:YES];
}

/*************************************************************************************************************/

- (IBAction)performFiltering
{
	
	std::cout<<"Reading image information"<<std::endl;
	
	typedef itk::RGBAPixel<unsigned int> RGBAPixelType;
	typedef unsigned char GrayscalePixelType;
	typedef itk::Image< RGBAPixelType, 2 > RGBAImageType;
	typedef itk::Image< GrayscalePixelType, 2 > GrayscaleImageType;
	typedef itk::ImageFileReader< RGBAImageType > RGBAReaderType;
	typedef itk::ImageFileReader< GrayscaleImageType > GrayscaleReaderType;
	typedef itk::ImageFileWriter< GrayscaleImageType > GrayscaleWriterType;
	typedef itk::RGBToLuminanceImageFilter<RGBAImageType, GrayscaleImageType> RGBAtoGrayscaleFilterType;
	typedef itk::BinaryThresholdImageFilter< GrayscaleImageType, GrayscaleImageType > BinaryThresholdFilterType; 
	
	RGBAReaderType::Pointer  RGBAReader = RGBAReaderType::New();
	GrayscaleReaderType::Pointer  grayReader = GrayscaleReaderType::New();
	GrayscaleWriterType::Pointer  grayWriter = GrayscaleWriterType::New();
	RGBAtoGrayscaleFilterType::Pointer  RGBA2GrayFilter = RGBAtoGrayscaleFilterType::New();
	BinaryThresholdFilterType::Pointer  binaryFilter = BinaryThresholdFilterType::New();
	
	itk::itkiOSImageIO::Pointer imageIO1 = itk::itkiOSImageIO::New();
	itk::itkiOSImageIO::Pointer imageIO2 = itk::itkiOSImageIO::New();
	
	UIImage* displayedImage = image.image;
	
	CGImageRef theImageRef= [displayedImage CGImage];
	size_t numBitsPerPixel = CGImageGetBitsPerPixel(theImageRef);
	size_t numBitsPerComponent = CGImageGetBitsPerComponent(theImageRef);
	CGSize imageSize = [displayedImage size];
	
	unsigned int nx = imageSize.width;
	unsigned int ny = imageSize.height;

	std::cout<<"The image is "<<nx<<" by "<<ny<<" pixels in size"<<std::endl;
	std::cout<<"There are "<<numBitsPerPixel<<" bits per pixel"<<std::endl;
	std::cout<<"There are "<<numBitsPerComponent<<" bits per component"<<std::endl;
	
	CGColorSpaceRef theColourSpace = CGImageGetColorSpace(theImageRef);
	size_t numColourSpaceComponents = CGColorSpaceGetNumberOfComponents(theColourSpace);
	
	if (numColourSpaceComponents == 1) 
	{
		std::cout<<"pixel type is grayscale"<<std::endl;
		grayReader->SetImageIO(imageIO1);
		imageIO1->SetFileName(image.image);
		grayReader->SetFileName("UIImage");
		grayReader->Update();
		
		binaryFilter->SetInput(grayReader->GetOutput());
		
		binaryFilter->SetOutsideValue(0);
		binaryFilter->SetInsideValue(255);
		
		binaryFilter->SetLowerThreshold(0.3*255);
		binaryFilter->SetUpperThreshold(0.7*255);
		
		std::cout<<"update binaryFilter"<<std::endl;
		binaryFilter->Update();
		
		grayWriter->SetInput(binaryFilter->GetOutput());
		grayWriter->SetImageIO( imageIO2 );
		
		UIImage* outputImage;
		
		imageIO2->SetFileName(outputImage);
		grayWriter->SetFileName("UIImage");
		
		grayWriter->Update();
		
		image.image = imageIO2->ReturnOutputImage();
	}
	else if (numColourSpaceComponents == 3)	// If the image has 3 components, it may or may not have an alpha
	{
		//CGImageAlphaInfo theAlphaInfo = CGImageGetAlphaInfo(theImageRef);
		
			std::cout<<"pixel type is RGB"<<std::endl;
			
			RGBAReader->SetImageIO(imageIO1);
			imageIO1->SetFileName(image.image);
			RGBAReader->SetFileName("UIImage");
			RGBAReader->Update();
			
			RGBA2GrayFilter->SetInput(RGBAReader->GetOutput());
			RGBA2GrayFilter->Update();
			
			binaryFilter->SetInput(RGBA2GrayFilter->GetOutput());
			
			binaryFilter->SetOutsideValue(0);
			binaryFilter->SetInsideValue(255);
			
			binaryFilter->SetLowerThreshold(0.3*255);
			binaryFilter->SetUpperThreshold(0.7*255);
			
			std::cout<<"update binaryFilter"<<std::endl;
			binaryFilter->Update();
			
			grayWriter->SetInput(binaryFilter->GetOutput());
			grayWriter->SetImageIO( imageIO2 );
			
			UIImage* outputImage;
			
			imageIO2->SetFileName(outputImage);
			grayWriter->SetFileName("UIImage");
			
			grayWriter->Update();
			
			image.image = imageIO2->ReturnOutputImage();
	}//end else if (numColourSpaceComponents == 3)
	else
	{
		std::cout<<"Could not tell the number of colour components. In function itkiOSImageIO::ReadImageInformation()"<<std::endl;
		exit(EXIT_FAILURE);
	}
	
	//[theImageRef release];
}
/*************************************************************************************************************/
-(void)imagePickerController:(UIImagePickerController*)picker
	   didFinishPickingImage:(UIImage*)theImage
				 editingInfo:(NSDictionary*)editingInfo
{
	
	std::cout << "Handling image acquisition" << std::endl;	
	image.image = theImage;
	currentImage = theImage;
	//[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[self dismissModalViewControllerAnimated:YES];
	
	return;
}

/*************************************************************************************************************/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
    NSLog(@"iphoneITKViewController: get a memory warning!");
	
    // Release any cached data, images, etc that aren't in use.
}

@end
