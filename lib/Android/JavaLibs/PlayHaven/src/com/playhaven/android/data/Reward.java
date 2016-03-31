package com.playhaven.android.data;

/**
 * Created by jeremyberman on 2/10/16.
 */

import android.os.Parcel;
import android.os.Parcelable;
import com.playhaven.android.util.JsonUtil;
import org.apache.commons.lang.builder.EqualsBuilder;
import org.apache.commons.lang.builder.HashCodeBuilder;
import org.apache.commons.lang.builder.ToStringBuilder;

/**
 * A representation of a Reward
 */
public class Reward implements Parcelable {
    /**
     * Construct a list of Reward objects from the JSON databound model
     *
     *
     * @param json model
     * @return a list of Reward objects
     */
    public static Reward fromJson(String json) {
        return new Reward(json);
    }

    private static final String NULL = "null";
    private String mRewardName;
    private Double mQuantity;

    /**
     * Construct a Reward from the JSON model
     *
     * @param json model
     */
    public Reward(String json)
    {
        this.mRewardName = JsonUtil.getPath(json, "$.reward_name");
        this.mQuantity = JsonUtil.getPath(json, "$.quantity");

        if (this.mQuantity == null)
            this.mQuantity = (double)1;

    }

    /**
     * Construct a Reward from a serialized Parcel
     *
     * @param in serialized parcel
     */
    public Reward(Parcel in)
    {
        readFromParcel(in);
    }

    /**
     * Describe the kinds of special objects contained in this Parcelable's marshalled representation.
     *
     * @return a bitmask indicating the set of special object types marshalled by the Parcelable.
     */
    @Override
    public int describeContents() {
        return 0;
    }

    /**
     * Flatten this object in to a Parcel.
     *
     * @param dest The Parcel in which the object should be written.
     * @param flags Additional flags about how the object should be written. May be 0 or Parcel#PARCELABLE_WRITE_RETURN_VALUE.
     */
    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeDouble(mQuantity);
        dest.writeString(mRewardName);
    }

    /**
     * Deserialize this object from a Parcel
     *
     * @param in parcel to read from
     */
    protected void readFromParcel(Parcel in)
    {
        mQuantity = in.readDouble();
        mRewardName = in.readString();
    }

    /**
     * Required Android annoyance
     */
    public static final Parcelable.Creator<Reward> CREATOR = new Creator<Reward>()
    {
        public Reward createFromParcel(Parcel in){return new Reward(in);}
        public Reward[] newArray(int size){return new Reward[size];}
    };

    public Double getQuantity() {
        return mQuantity;
    }

    public String getRewardName() {
        return mRewardName;
    }

    @Override
    public String toString() {
        return ToStringBuilder.reflectionToString(this);
    }

    @Override
    public int hashCode() {
        return HashCodeBuilder.reflectionHashCode(this);
    }

    @Override
    public boolean equals(Object other) {
        return EqualsBuilder.reflectionEquals(this, other);
    }
}