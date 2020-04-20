using Microsoft.VisualBasic;
using BaseClasses;
using BaseClasses.Data;
using System;
using System.IO;
using System.Text.RegularExpressions;

/// <summary>
/// The DatabaseObjects class contains a set of functions that provide
/// access to the database by using table or field names.  The class
/// allows conversion of names into the proper table object and
/// retrieval of values for field name.
/// </summary>
/// <remarks></remarks>
public class DatabaseObjects
{

    private const string ASSEMBLY_NAME = "POViewer.Business";
    private const string BUSINESS_NAMESPACE = "POViewer.Business";


    /// <summary>
    /// Returns the BaseTable object for the given table name.
    /// Determines if this is a Table, View or Query - and then
    /// calls GetType to retrieve and return the object.
    /// </summary>
    /// <param name="tableName">tableName whose object is desired</param>
    /// <returns>A BaseTable object for the given table name.</returns>
    public static BaseTable GetTableObject(string tableName)
    {
        string expandedTableName = string.Empty;
        string TYPE_FORMAT = "{0}.{1}{2},{3}";

        Regex rgx = new Regex("[^a-zA-Z0-9]");
        tableName = rgx.Replace(tableName, "_");

        // First see if it is a table.
        try
        {
            expandedTableName = string.Format(TYPE_FORMAT, BUSINESS_NAMESPACE, tableName, "Table", ASSEMBLY_NAME);
            System.Type.GetType(expandedTableName, true, true);
        }
        catch
        {
            // It was not really a table name - so reset and try again with a view or a query.
            expandedTableName = string.Empty;
        }

        // Check if it is a view.
        if (expandedTableName == string.Empty)
        {
            try
            {
                expandedTableName = string.Format(TYPE_FORMAT, BUSINESS_NAMESPACE, tableName, "View", ASSEMBLY_NAME);
                System.Type.GetType(expandedTableName, true, true); 
            }
            catch
            {
                // It was not really a view name - so reset and try again with a query.
                expandedTableName = string.Empty;
            }
        }


        // Check if it is a query.
        if (expandedTableName == string.Empty)
        {
            try
            {
                expandedTableName = string.Format(TYPE_FORMAT, BUSINESS_NAMESPACE, tableName, "Query", ASSEMBLY_NAME);
                System.Type.GetType(expandedTableName, true, true);
            }
            catch
            {
                // Still no luck.
                expandedTableName = string.Empty;
            }
        }


        if (expandedTableName != string.Empty)
        {
            // OK, looks like we found an object.
            try
            {
                BaseTable t = BaseTable.CreateInstance(expandedTableName);
                return t;
            }
            catch
            {
                // Ignore, fall through and return Nothing
            }
        }

        // Could not find a table.
        return null;
    }

}

