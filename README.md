DXImagePicker
=============

Simple Imager picker which mimic Facebook's UI and UX

###Demo


![gif](picker.gif)

###Purpose

We wanna an image picker which contains both camera capture and albums selection(indexed) in a single view controller, just one that does not include push and present other stuff. Like facebook's app does! So, here comes this project.

###How to use

1. Drop DXImagePicker into your project and #import "DXImagePicker.h" somewhere you need
2. In some your viewController method, doing this:

		// present the picker and set the delegate, note: you'd better present not push.
		- (void)presentPhotoSelectBrowser
		{
		    DXImagePicker *browser = [DXImagePicker new];
		    browser.delegate = self;
		    UINavigationController *navcon = [[UINavigationController alloc] initWithRootViewController:browser];
		    [self presentViewController:navcon animated:YES completion:nil];
		}
	
		// implement the delegate method, and update your UI
		- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectAssets:(NSArray *)assets didCamptureImage:(UIImage *)image
		{
		
		    [self.images removeAllObjects];
		    [self.collectionView reloadData];
		    
		    
		    for (ALAsset *asset in assets) {
		        UIImage *thumbnail = [[UIImage alloc] initWithCGImage:asset.thumbnail];
		        [self.images addObject:thumbnail];
		    }
		    
		    if (image) {
		        [self.images addObject:image];
		    }
		    
		    
		    [self.collectionView reloadData];
		    self.selectedAssetNames = [DXImagePicker getAssetNamesByAssets:assets];
		}


3. If you don't need to let the user continue to choosing on last choosen state, that's all. But if you did, here's some property need to be set.

		//Before presenting imagePicker, you need set this. Where does it come from?
		dx_imagePickerController:didSelectAssets:didCamptureImage: this delegate return the assets, you need to hold the [DXImagePicker getAssetNamesByAssets:assets] assets names; and set that to this property.
	
		@property (nonatomic, strong) NSArray *shouldSelectedAssetFileNames;


		//dx_imagePickerController:didSelectAssets:didCamptureImage: callback this, and also you need an ivar to hold it, next time you present the imagePicker, set this property.
				
		@property (nonatomic, strong) NSString *shouldSelectAlbumName;



	
	



	

