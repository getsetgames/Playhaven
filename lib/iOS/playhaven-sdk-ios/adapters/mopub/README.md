# Integrating PlayHaven and Mopub

Connecting your PlayHaven account to Mopub is easy and can be completed in just a few steps.

## In the Mopub dashboard:

1. Login to your Mopub account and click on the **Networks** tab at the top of the page
2. Click the **Add a Network** button in the upper right corner
3. In the popover, click on the PlayHaven link
4. Enter your PlayHaven token, secret and target placement name
5. Save your changes

### Prior to official Mopub certification:

1. Login to your Mopub account and click on the **Networks** tab at the top of the page
2. Click the **Add a Network** button in the upper right corner
3. In the popover, click **Custom Native Network** in the **Additional Networks** section
4. Give your Costum Native Network a title (ie. PlayHaven)
5. Under **Custom Event Class** enter **PlayHavenInterstitialCustomEvent** (the name of our custom Adapter class)
6. Under **Custom Event Class Data** enter the flowing JSON object, substituting in your PlayHaven token, secret and target placement name:
```javascript
{
	"token":"YOUR_PLAYHAVEN_TOKEN",
	"secret":"YOUR_PLAYHAVEN_SECRET",
	"placement":"PLACEMENT_ID"
}
```
7. Save your changes

## In your app:

1. Make sure you have added the PlayHaven and Mopub SDKs to your project.
2. Add **PlayHavenInterstitialCustomEvent.h** and **PlayHavenInterstitialCustomEvent.m** to your project.

## That's it! 

Now everytime Mopub returns a PlayHaven custom event for a particular ad unit, the Mopub SDK will present a PlayHaven ad.