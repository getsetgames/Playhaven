//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2015 Get Set Games Inc. All rights reserved.
//

#include "PlayhavenComponent.h"
#include "PlayhavenPrivatePCH.h"

void UPlayhavenComponent::OnRegister()
{
	Super::OnRegister();
    
    UPlayhavenComponent::RequestWillGetContentDelegate.AddUObject(this, &UPlayhavenComponent::RequestWillGetContent_Handler);
}

void UPlayhavenComponent::OnUnregister()
{
	Super::OnUnregister();
    
    UPlayhavenComponent::RequestWillGetContentDelegate.RemoveAll(this);
}
UPlayhavenComponent::FPlayhavenPlacementDelegate UPlayhavenComponent::RequestWillGetContentDelegate;
