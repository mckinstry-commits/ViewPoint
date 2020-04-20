using System;
using System.Data;
using System.Data.OleDb;
using System.Configuration;
using System.Text;
using System.IO;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;

namespace ViewpointXRef.UI
{
    /// <summary>
    /// Summary description for AccessParser
    /// </summary>
    public class AccessParser : Parser, IDisposable
    {
        #region Private Member

        private string fileName = string.Empty;
        private string commandText = string.Empty;
        private OleDbCommand command = null;
        private OleDbConnection connection = null;
        private OleDbDataReader reader = null;
        private string connectionString = string.Empty;
        private string _tableName = string.Empty;
        

        #endregion
        #region Properties
        internal string ConnectionStringOne
        {
            get
            {
                if (HttpContext.Current.Session["pwd"] != null)
                {
                    this.connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;" + "Data Source=" + this.fileName + ";" + "Jet OLEDB:Database Password=" + HttpContext.Current.Session["pwd"].ToString() + ";";
                    return this.connectionString;
                }
                else
                {
                    this.connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;" + "Data Source=" + this.fileName + ";" + "Persist Security Info=False;";
                    return this.connectionString;
                }
            }
        }
        internal string ConnectionStringTwo
        {
            get
            {
                this.connectionString = "Provider=Microsoft.Jet.OLEDB.4.0;" + "Data Source=" + this.fileName + ";";
                return this.connectionString;
            }
        }
        internal string TableName
        {
            get
            {
                if (!IsValidTableName(this._tableName))
                {
                    string aliasName = this._tableName.Replace(" ", "_") + "_";
                    return string.Format("[{0}][{1}]", this._tableName, aliasName);
                }
                else
                {
                    return this._tableName;
                }
            }
        }

        private bool IsValidTableName(string tableName)
        {

            char[] specialChar = new char[] {'~', '-', '!', '@', '#', '$', '%', '^', '&', '*','(', ')', '`', '|', '\\', ':', ';', '\'', '<', ',', '>', '.', '/', '?', '[', ']', '{', '}'};
            if (tableName.IndexOfAny(specialChar) > -1)
            {
                return false;
            }
            else
            {
                return true;
            }
        } 


        #endregion
        public AccessParser(string file, string tableName)
        {
            //
            // Add constructor logic here
            //
            this.fileName = file;
            bool error = false;
            bool isConnectionOpen = false;
            this._tableName = tableName;
            this.connection = new OleDbConnection(this.ConnectionStringOne);
            this.commandText = "SELECT * FROM " + this.TableName;
            this.command = new OleDbCommand(this.commandText, this.connection);

            try
            {
                this.connection.Open();
                isConnectionOpen = true;
                this.reader = this.command.ExecuteReader();

            }
            catch (Exception ex)
            {
                if (!isConnectionOpen)
                {
                    this.connection = null;
                    this.command = null;
                    this.connection = new OleDbConnection(this.ConnectionStringTwo);
                    this.command = new OleDbCommand(this.commandText, this.connection);
                    try
                    {
                        this.connection.Open();
                        this.reader = this.command.ExecuteReader();

                    }
                    catch (Exception exe)
                    {
                        error = true;
                        throw new Exception(exe.Message);
                    }
                    if (error)
                    {
                        if (this.connection.State == ConnectionState.Open && this.connection != null)
                        {
                            this.connection.Close();
                        }
                        throw ex;
                    }
                }
                else
                {
                    if (this.connection.State == ConnectionState.Open && this.connection != null)
                    {
                        this.connection.Close();
                    }
                    throw ex;
                }
            }
        }
        #region Parser member

        public override void Reset()
        {
            // throw new NotImplementedException();
        }

        public override string[] GetNextRow()
        {
            ArrayList row = new ArrayList();
            int columnIndex = 0;
            if (this.connection.State != ConnectionState.Closed)
            {

                if (this.reader.Read())
                {
                    for (int columns = 0; columns < this.reader.FieldCount; columns++)
                    {
                        try
                        {
                            row.Add(this.reader[columnIndex].ToString());
                        }
                        catch (Exception ex)
                        {
                            throw new Exception(ex.Message);
                        }
                        columnIndex += 1;
                    }
                }
            }
            if (row.Count != 0)
            {
                return (string[])row.ToArray(typeof(string));
            }

            return null;
        }

        public override void Close()
        {
            this.reader.Close();
            this.reader = null;
            this.connection.Close();
            this.connection = null;

        }
        #endregion

        #region IDisposable Members

        void IDisposable.Dispose()
        {
            //throw new NotImplementedException();
            if (this.reader != null)
            {
                this.reader.Close();
                this.reader.Dispose();
            }
            if (this.connection != null)
            {
                this.connection.Close();
                this.connection.Dispose();
            }

        }

        #endregion
    }
}