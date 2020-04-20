using System;
using System.Data;
using System.Data.OleDb;
using System.Configuration;
using System.Text;
using System.IO;
using System.Collections;


namespace ViewpointXRef.UI
{
    /// <summary>
    /// Summary description for ExcelParser
    /// </summary>
    public class ExcelParser : Parser, IDisposable
    {
        #region Private Member

        private string fileName = string.Empty;
        private string commandText = string.Empty;
        private OleDbCommand command = null;
        private OleDbConnection connection = null;
        private OleDbDataReader reader = null;
        private string connectionString = string.Empty;
        

        #endregion

        #region Properties

        public OleDbConnection Connection
        {
            get { return connection; }
            set { connection = value; }
        }
        public string FileName
        {
            get { return fileName; }
            set { fileName = value; }
        }


        internal string ConnectionStringOne
        {
            get
            {
                this.connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;" + "Data Source=" + this.fileName + ";" + "Extended Properties=\"Excel 12.0;HDR=No;IMEX=1\"";
                return this.connectionString;
            }

        }
        internal string ConnectionStringTwo
        {
            get
            {
                this.connectionString = "Provider=Microsoft.Jet.OLEDB.4.0;" + "Data Source=" + this.fileName + ";" + "Extended Properties=\"Excel 8.0;HDR=No;IMEX=1\"";
                return this.connectionString;
            }

        }

        #endregion

        public ExcelParser(string file, string sheetName)
        {
            //
            // Add constructor logic here
            //
            this.fileName = file;
            bool error = false;
            bool isConnectionOpen = false;
            this.connection = new OleDbConnection(this.ConnectionStringOne);
            this.commandText = "SELECT * FROM [" + sheetName + "$]";
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