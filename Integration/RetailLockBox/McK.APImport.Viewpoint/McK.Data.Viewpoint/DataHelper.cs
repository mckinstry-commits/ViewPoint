using System;
using System.Linq;
using System.Data.SqlClient;
using System.Reflection;

namespace McK.Data.Viewpoint
{
    public static class DataHelper
    {
        /// <summary>
        /// Populates a class model record from an SqlDataReader
        /// </summary>
        /// <param name="reader">SqlDataReader</param>
        /// <param name="model">Class Model</param>
        /// <param name="recordProperties">Class Model Properties</param>
        public static void ReaderToModel(SqlDataReader reader, object model)
        {
            PropertyInfo[] recordProperties = model.GetType().GetProperties();

            // populate 'record' from reader
            for (int field = 0; field <= reader.FieldCount - 1; field++)
            {
                // get property
                var prop = recordProperties.OfType<PropertyInfo>().Where(x => x.Name == reader.GetName(field)).FirstOrDefault();

                if (prop != null) // if property exists in model
                {
                    // get property value 
                    var value = reader[field].GetType() == typeof(DBNull) ? null : reader[field];

                    prop.SetValue(model, value);
                } 
                // else ignore field
            }
        }
    }
}
