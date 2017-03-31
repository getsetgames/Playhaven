//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

#pragma once

#include "Components/ActorComponent.h"
#include "PlayhavenFunctions.h"
#include "PlayhavenComponent.generated.h"

UCLASS(ClassGroup=Advertising, HideCategories=(Activation, "Components|Activation", Collision), meta=(BlueprintSpawnableComponent))
class UPlayhavenComponent : public UActorComponent
{
	GENERATED_BODY()
	
public:

    DECLARE_MULTICAST_DELEGATE(FPlayhavenDelegate);
    DECLARE_MULTICAST_DELEGATE_OneParam(FPlayhavenPlacementDelegate, FString);
    
    
    static FPlayhavenPlacementDelegate RequestWillGetContentDelegate;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FPlayhavenDynDelegate);
    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FPlayhavenPlacementDynDelegate, FString, Placement);
    
    UPROPERTY(BlueprintAssignable)
    FPlayhavenPlacementDynDelegate RequestWillGetContent;
    
	void OnRegister() override;
	void OnUnregister() override;
	
private:	
	void RequestWillGetContent_Handler(FString Placement) { RequestWillGetContent.Broadcast(Placement); }
    
    
};
