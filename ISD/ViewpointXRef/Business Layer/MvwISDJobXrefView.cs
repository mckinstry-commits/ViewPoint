// This is a "safe" class, meaning that it is created once 
// and never overwritten. Any custom code you add to this class 
// will be preserved when you regenerate your application.
//
// Typical customizations that may be done in this class include
//  - adding custom event handlers
//  - overriding base class methods

using System;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace ViewpointXRef.Business
{

/// <summary>
/// Provides access to the schema information and record data of a database table (or view).
/// See <see cref="BaseMvwISDJobXrefView"></see> for additional information.
/// </summary>
/// <remarks>
/// See <see cref="BaseMvwISDJobXrefView"></see> for additional information.
/// <para>
/// This class is implemented using the Singleton design pattern.
/// </para>
/// </remarks>
/// <seealso cref="BaseMvwISDJobXrefView"></seealso>
/// <seealso cref="BaseMvwISDJobXrefSqlView"></seealso>
/// <seealso cref="MvwISDJobXrefSqlView"></seealso>
/// <seealso cref="MvwISDJobXrefDefinition"></seealso>
/// <seealso cref="MvwISDJobXrefRecord"></seealso>
/// <seealso cref="BaseMvwISDJobXrefRecord"></seealso>
[SerializableAttribute()]
public class MvwISDJobXrefView : BaseMvwISDJobXrefView, System.Runtime.Serialization.ISerializable, ISingleton
{

#region "ISerializable Members"

    /// <summary>
    /// Overridden to use the <see cref="MvwISDJobXrefView_SerializationHelper"></see> class 
    /// for deserialization of <see cref="MvwISDJobXrefView"></see> data.
    /// </summary>
    /// <remarks>
    /// Since the <see cref="MvwISDJobXrefView"></see> class is implemented using the Singleton design pattern, 
    /// this method must be overridden to prevent additional instances from being created during deserialization.
    /// </remarks>
    void System.Runtime.Serialization.ISerializable.GetObjectData(
        System.Runtime.Serialization.SerializationInfo info, 
        System.Runtime.Serialization.StreamingContext context)
    {
        info.SetType(typeof(MvwISDJobXrefView_SerializationHelper)); //No other values need to be added
    }

#region "Class MvwISDJobXrefView_SerializationHelper"

    [SerializableAttribute()]
    private class MvwISDJobXrefView_SerializationHelper: System.Runtime.Serialization.IObjectReference
    {
        //Method called after this object is deserialized
        public virtual object GetRealObject(System.Runtime.Serialization.StreamingContext context)
        {
            return MvwISDJobXrefView.Instance;
        }
    }

#endregion

#endregion

    /// <summary>
    /// References the only instance of the <see cref="MvwISDJobXrefView"></see> class.
    /// </summary>
    /// <remarks>
    /// Since the <see cref="MvwISDJobXrefView"></see> class is implemented using the Singleton design pattern, 
    /// this field is the only way to access an instance of the class.
    /// </remarks>
    public readonly static MvwISDJobXrefView Instance = new MvwISDJobXrefView();

    public MvwISDJobXrefView()
    {
    }


} // End class MvwISDJobXrefView

}
