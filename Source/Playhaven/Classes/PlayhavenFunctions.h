//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

#pragma once

#include "PlayhavenFunctions.generated.h"

UCLASS(NotBlueprintable)
class UPlayhavenFunctions : public UObject {
	GENERATED_BODY()
	
public:
    UFUNCTION(BlueprintCallable, meta = (Keywords = "playhaven ad advertising analytics"), Category = "Playhaven")
    static void PlayhavenContentRequest(FString placement, bool showsOverlayImmediately);
    
    UFUNCTION(BlueprintCallable, meta = (Keywords = "playhaven ad advertising analytics"), Category = "Playhaven")
    static void PlayhavenTrackPurchase(FString productID, int quantity, float price, int resolution, FString receiptData);
    
    UFUNCTION(BlueprintCallable, meta = (Keywords = "playhaven ad advertising analytics"), Category = "Playhaven")
    static void PlayhavenContentRequestPreload(FString placement);
    
    UFUNCTION(BlueprintCallable, meta = (Keywords = "playhaven ad advertising analytics"), Category = "Playhaven")
    static void PlayhavenSetOptOutStatus(bool optOutStatus);
};
