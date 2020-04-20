using Microsoft.VisualBasic;
using System.IO;
using BaseClasses.Data;
using System;
using System.Collections;
using System.Data.OleDb;
using System.Data;
using NPOI.SS.UserModel;
using NPOI.HSSF.UserModel;  

namespace ViewpointXRef
{
    public enum ISDDataType
    {
        ISDNotSet = 0,
        ISDString = 1,
        ISDNumber = 2,
        ISDDateTime = 3,
        ISDBoolean = 4,
        ISDInteger = 5,
        ISDError = 999,
    }


    public class ISDWorkbook
    {
        public ArrayList Worksheets = new ArrayList();

        public ISDWorkbookProperties Properties = new ISDWorkbookProperties();


        private string GenerateUniquePath(string filename, string extension) {
            int suffix = 0;
            string fullpath;

            do {
                suffix++;
                fullpath = System.Web.HttpContext.Current.Server.MapPath("../Temp/" + filename + "_" + suffix + "." + extension);
            } while (System.IO.File.Exists(fullpath));

            return fullpath;
        }


        private string GetColumnDefinitions(ArrayList cols, ArrayList headerCells, ArrayList dataCells, bool addType)
        {
            string result = "";
            int i = 0;

            foreach (ISDWorksheetCell headerCell in headerCells)
            {
                if (!result.Equals("")) {
                    result += ", ";
                }
                result += "[" + headerCell.Text + "]";

                if (addType)
                {
                    ISDWorksheetCell dataCell = (ISDWorksheetCell)dataCells[i];

                    result += " varchar(" + cols[i] + ")";
                }

                i++;
            }

            return result;
        }


        private string GetRowData(ArrayList cells) {
            string result = "";
            string value = "";

            foreach (ISDWorksheetCell cell in cells)
            {
                if (!result.Equals(""))
                {
                    result += ", ";
                }

                value = cell.Text.Replace("'", "''");

                if (value.Length > 255)
                {
                    value = value.Substring(0, 255);
                }

                result += "'" + value + "'";
            }

            return result;
        }

        public void Save(System.IO.Stream OutputStream, System.Web.HttpResponse response)
        {
            string filename = "Export_" + Guid.NewGuid().ToString();
            string completePathOne = GenerateUniquePath(filename, "xlsx");
            string completePathTwo = GenerateUniquePath(filename, "xls");
            string completePath = null;
            string tableName = null;

            ISDWorksheet ws = (ISDWorksheet)this.Worksheets[0];
            ISDTable ta = ws.Table;
            tableName = ws.Name;
            ArrayList rows = ta.Rows;
            ISDWorksheetRow row0 = null;

            if (rows.Count > 0)
            {
                row0 = (ISDWorksheetRow)rows[0];
            }

            ISDWorksheetRow row1 = row0;

            if (rows.Count > 1)
            {
                row1 = (ISDWorksheetRow)rows[1];
            }

            ArrayList cols = ta.Columns;
            string colDefs = GetColumnDefinitions(cols, row0.Cells, row1.Cells, true);
            string colNames = GetColumnDefinitions(cols, row0.Cells, row1.Cells, false);

            completePath = completePathTwo;

            HSSFWorkbook hssfwb = new HSSFWorkbook();

            IDataFormat format = hssfwb.CreateDataFormat();

            ISheet sh = hssfwb.CreateSheet("Sheet1");

            int rIndex = 0;

            IRow r = sh.CreateRow(rIndex);

            int c = 0;


            HSSFCellStyle[] styles = new HSSFCellStyle[row0.Cells.Count + 1];

            foreach (ISDWorksheetCell hCell in row0.Cells)
            {
                HSSFCellStyle style = (HSSFCellStyle)hssfwb.CreateCellStyle();
                ICell ce = r.CreateCell(c);

                ce.SetCellValue(hCell.Text);

                style.WrapText = true;
                styles[c] = (HSSFCellStyle)hssfwb.CreateCellStyle();
                ce.CellStyle = style;
                c += 1;
            }

            for (rIndex = 1; rIndex <= rows.Count - 1; rIndex++)
            {
                ISDWorksheetRow currentRow = (ISDWorksheetRow)rows[rIndex];

                r = sh.CreateRow(rIndex);

                c = 0;

                for (int i = 0; i <= currentRow.Cells.Count - 1; i++)
                {
                    //myValue = myValue.Replace("$", "").Replace(",", "")
                    ICell ce = r.CreateCell(c);

                    HSSFCellStyle style = styles[i];
                    ISDWorksheetCell dCell = (ISDWorksheetCell)currentRow.Cells[i];

                    string formatStr = dCell.Format;
                    if (dCell.Type == ISDDataType.ISDInteger || dCell.Type == ISDDataType.ISDNumber)
                    {
                        ce.SetCellType(CellType.NUMERIC);

                        if (dCell.Value != null)
                        {
                            ce.SetCellValue(Convert.ToDouble(dCell.Value));
                        }

                        if (GetBuildInFormat(dCell.Format) > 0)
                        {
                            style.DataFormat = HSSFDataFormat.GetBuiltinFormat(dCell.Format);

                        }
                        else
                        {
                            System.Globalization.NumberFormatInfo info = System.Globalization.CultureInfo.CurrentCulture.NumberFormat;
                            if (string.IsNullOrEmpty(dCell.Format) || dCell.Format == null)
                            {
                                formatStr = "##0.00";
                            }
                            else if (dCell.Format.Contains("C") || dCell.Format.Contains("c"))
                            {
                                formatStr = info.CurrencySymbol + "##0.00";
                            }
                            else if (dCell.Format.Contains("P") || dCell.Format.Contains("p"))
                            {
                                formatStr = "##0.00" + info.PercentSymbol;
                            }
                            else if (dCell.Format.Contains(info.CurrencySymbol) || dCell.Format.Contains(info.PercentSymbol))
                            {
                                // use the user given display format
                            }
                            else
                            {
                                formatStr = "##0.00";
                            }
                            style.DataFormat = format.GetFormat(formatStr);
                        }

                    }
                    else if (dCell.Type == ISDDataType.ISDDateTime)
                    {
                        if (dCell.Value != null)
                        {
                            ce.SetCellType(CellType.NUMERIC);
                            ce.SetCellValue(Convert.ToDateTime(dCell.Value));
                        }

                        if (GetBuildInFormat(dCell.Format) > 0)
                        {
                            style.DataFormat = HSSFDataFormat.GetBuiltinFormat(dCell.Format);
                        }
                        else
                        {
                            System.Globalization.DateTimeFormatInfo info = System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat;

                            // convert the date format understood by Excel
                            // see http://msdn.microsoft.com/en-us/library/az4se3k1(v=vs.71).aspx
                            switch (dCell.Format)
                            {
                                case "d":
                                    formatStr = info.ShortDatePattern;
                                    break;
                                case "D":
                                    formatStr = info.LongDatePattern;
                                    break;
                                case "t":
                                    formatStr = info.ShortTimePattern;
                                    break;
                                case "T":
                                    formatStr = info.LongTimePattern;
                                    break;
                                case "f":
                                    formatStr = info.LongDatePattern + " " + info.ShortTimePattern;
                                    break;
                                case "F":
                                    formatStr = info.FullDateTimePattern;
                                    break;
                                case "g":
                                    formatStr = info.ShortDatePattern + " " + info.ShortTimePattern;
                                    break;
                                case "G":
                                    formatStr = info.ShortDatePattern + " " + info.LongTimePattern;
                                    break;
                                case "M":
                                case "m":
                                    formatStr = info.MonthDayPattern;
                                    break;
                                case "R":
                                case "r":
                                    formatStr = info.RFC1123Pattern;
                                    break;
                                case "s":
                                    formatStr = info.SortableDateTimePattern;
                                    break;
                                case "u":
                                    formatStr = info.UniversalSortableDateTimePattern;
                                    break;
                                case "U":
                                    formatStr = info.FullDateTimePattern;
                                    break;
                                case "Y":
                                case "y":
                                    formatStr = info.YearMonthPattern;
                                    break;
                                default:
                                    formatStr = info.ShortDatePattern;
                                    break;
                            }

                            // some pattern above might return t but this is not recognized by Excel, so remove it
                            formatStr = formatStr.Replace("t", "");
                            style.DataFormat = format.GetFormat(formatStr);

                        }

                    }
                    else
                    {
                        ce.SetCellType(CellType.STRING);
                        if (dCell.Value != null)
                        {
                            string myValue = dCell.Text;
                            if (myValue.Length > 255)
                            {
                                myValue = myValue.Substring(0, 255);
                            }
                            ce.SetCellValue(myValue);
                        }

                        if (GetBuildInFormat(dCell.Format) > 0)
                        {
                            style.DataFormat = HSSFDataFormat.GetBuiltinFormat(dCell.Format);
                        }
                        else
                        {
                            style.DataFormat = HSSFDataFormat.GetBuiltinFormat("TEXT");
                            style.WrapText = true;
                        }

                    }

                    ce.CellStyle = style;
                    c += 1;
                }
            }

            MemoryStream ms = new MemoryStream();
            hssfwb.Write(ms);

            string NPOIDownloadFileName = this.Properties.Title;

            if (completePath.EndsWith(".xlsx"))
            {
                NPOIDownloadFileName += ".xlsx";
            }
            else
            {
                NPOIDownloadFileName += ".xls";
            }

            response.ClearHeaders();
            response.Clear();
            response.Cache.SetCacheability(System.Web.HttpCacheability.Private);
            response.Cache.SetMaxAge(new TimeSpan(0));
            response.Cache.SetExpires(new DateTime(0));
            response.Cache.SetNoServerCaching();
            response.AppendHeader("Content-Disposition", ("attachment; filename=\"" + (NPOIDownloadFileName + "\"")));
            response.ContentType = "application/vnd.ms-excel";

            OutputStream.Write(ms.ToArray(), 0, ms.ToArray().Length);

            return;
        }

        private short GetBuildInFormat(string format)
        {
            if (string.IsNullOrEmpty(format) || format == null)
            {
                return -1;
            }
            else
            {
                return HSSFDataFormat.GetBuiltinFormat(format);
            }
        }
    }

    public class ISDWorkbookProperties
    {
        public string Title = "";
    }


    public class ISDWorksheet
    {
        public ISDTable Table = new ISDTable();
        public string Name = "";

        public ISDWorksheet(string name) {
            Name = name;
        }
    }

    public class ISDTable
    {
        public ArrayList Rows = new ArrayList();
        public ArrayList Columns = new ArrayList();
    }


    public class ISDWorksheetRow
    {
        public ArrayList Cells = new ArrayList();
    }


    public class ISDWorksheetCell
    {
        public object Value = "";
        public ISDDataType Type = ISDDataType.ISDString;
        public string StyleID = "";

        public string Format = "";
        public string Text
        {
            get
            {
                if (Value == null)
                {
                    return null;
                }
                return Value.ToString();
            }
        }

        public ISDWorksheetCell()
        {
            Value = "";
            Type = ISDDataType.ISDString;
            StyleID = "";
        }

        public ISDWorksheetCell(object text__1)
        {
            Value = text__1;
            Type = ISDDataType.ISDString;
            StyleID = "";
        }







        public ISDWorksheetCell(object text__1, string styleID__2)
        {
            Value = text__1;
            Type = ISDDataType.ISDString;
            StyleID = styleID__2;
        }

        public ISDWorksheetCell(object text__1, ISDDataType type__2, string styleID__3, string format__4)
        {
            Value = text__1;
            Type = type__2;
            StyleID = styleID__3;
            Format = format__4;
        }
    }



    /// <summary>
    /// Base class to export data to CSV or Excel
    /// </summary>
    abstract public class ExportDataBaseClass
    {
        #region "Properties"
        protected int pageSize = 5000;

        protected String _headerString;
        protected String HeaderString
        {
            get { return _headerString; }
            set { _headerString = value; }
        }

        abstract protected string Title
        {
            get;
        }
        #endregion

        #region "Constructor"
        protected ExportDataBaseClass()
        {
            HeaderString = null;
        }

        protected ExportDataBaseClass(String header)
        {
            HeaderString = header;
        }
        #endregion

        #region "Public Methods"

        // SetsResponse header and cache 
        public void SetupResponse(System.Web.HttpResponse response, string fileName)
        {
            response.ClearHeaders();
            response.Clear();
            response.Cache.SetCacheability(System.Web.HttpCacheability.Private);
            response.Cache.SetMaxAge(new TimeSpan(0));
            response.Cache.SetExpires(new DateTime(0));
            response.Cache.SetNoServerCaching();
            response.AppendHeader("Content-Disposition", ("attachment; filename=\"" + (fileName + "\"")));
        }

        public abstract void Export(System.Web.HttpResponse response);

        #endregion
    }

    // The ExportToCSVBaseClass class exports to CSV file and sends the file to the response stream.
    abstract public class ExportToCSVBaseClass : ExportDataBaseClass
    {
        #region "Properties"

        StreamWriter _writer;
        private StreamWriter Writer
        {
            get { return _writer; }
            set { _writer = value; }
        }
        #endregion

        #region "Constructor"
        protected ExportToCSVBaseClass() : base() { }

        protected ExportToCSVBaseClass(String header) : base(header) { }
        #endregion

        #region "Private Methods"

        virtual protected bool WriteColumnHeader(bool exportRawValues)
        {
            // If the DisplayString is not null then, write the contents of DisplayString as column headers
            if (base.HeaderString != null && base.HeaderString != "")
            {
                Writer.Write(HeaderString.Replace("\"", "\"\""));
                return true;
            }

            return false;
        }

        protected String separator = System.Globalization.CultureInfo.CurrentCulture.TextInfo.ListSeparator;

        protected void WriteColumnTitle(string val)
        {
            Writer.Write("\"" + (val.Replace("\"", "\"\"") + "\"" + separator));
        }

        protected internal void WriteColumnData(object val, bool isString)
        {
            if (val != null && (isString || (val as string).Contains(separator)))
            {
                Writer.Write("\"" + ((val as string).Replace("\"", "\"\"") + "\""));
            }
            else
            {
                Writer.Write(val);
            }

            Writer.Write(separator);
        }

        protected internal void WriteNewRow()
        {
            Writer.WriteLine();
        }
        #endregion

        #region "Public Methods"

        public void StartExport(System.Web.HttpResponse response, bool exportRawValues)
        {
            if (response == null)
                return;

            string fileName = Title + ".csv";
            SetupResponse(response, fileName);
            response.ContentType = "text/plain";

            Writer = new StreamWriter(response.OutputStream, System.Text.Encoding.UTF8);

            //  First write out the Column Headers
            this.WriteColumnHeader(exportRawValues);

            Writer.WriteLine();
        }

        public void FinishExport(System.Web.HttpResponse response)
        {
            Writer.Flush();

            // Need to call Response.End() so nothing will be attached to a file
            // System.Web.HttpResponse.End() function will throw System.Threading.ThreadAbortException
            // indicating that the current response ends prematurely - that's what we want
            response.End();
        }
        #endregion
    }

    /// <summary>
    /// The ExportToExcelBaseClass provides common functionality 
    /// used for exports to Excel and sends the XLS file to the response stream.
    /// </summary>
    abstract public class ExportToExcelBaseClass : ExportDataBaseClass
    {
        #region "Properties"

        private ISDWorkbook _ISDexcelBook;
        private ISDWorkbook ISDExcelBook
        {
            get { return _ISDexcelBook; }
            set { _ISDexcelBook = value; }
        }

        private ISDWorksheet _ISDexcelSheet;
        private ISDWorksheet ISDExcelSheet
        {
            get { return _ISDexcelSheet; }
            set { _ISDexcelSheet = value; }
        }

        private ISDWorksheetRow _ISDexcelRow;
        private ISDWorksheetRow ISDExcelRow
        {
            get { return _ISDexcelRow; }
            set { _ISDexcelRow = value; }
        }
        #endregion

        #region "Constructor"
        protected ExportToExcelBaseClass()
        {
            base.HeaderString = null;
        }

        protected ExportToExcelBaseClass(String header)
        {
            base.HeaderString = header;
        }
        #endregion

        #region "Protected Methods"

        // Add column to excel book, creates style for that column set's format 
        // before call to this function empty row needs to be added
        protected internal void AddColumnToExcelBook(int column, string caption, ISDDataType type, int width, string format)
        {
            if (ISDExcelRow == null)
                return;

            ISDExcelRow.Cells.Add(new ISDWorksheetCell(caption, "HeaderRowStyle"));
            ISDExcelSheet.Table.Columns.Add(width);
        }

        // Add cell with data to existing row
        // column - column number to set correct format for this cell
        // name - column name
        // entityType - EntityType instance, that holds types definitions for this table 
        // val - data value for this cell
        protected internal void AddCellToExcelRow(int column, ISDDataType type, object val, string format)
        {
            String styleName = "Style"; //name of the format style

            if (ISDExcelRow == null)
                return;

            ISDExcelRow.Cells.Add(new ISDWorksheetCell(val, type, (styleName + column), format));
        }

        protected internal void AddRowToExcelBook()
        {
            if (ISDExcelSheet == null)
                return;

            ISDExcelRow = new ISDWorksheetRow();
            ISDExcelSheet.Table.Rows.Add(ISDExcelRow);
        }

        // calls SetupResponse to set header and cache and saves Excel file to HttpResponse
        protected internal void SaveExcelBook(System.Web.HttpResponse response)
        {
            try
            {
                ISDExcelBook.Save(response.OutputStream, response);
            }
            catch (Exception ex)
            {
                throw ex;
            }

            // Need to call Response.End() so nothing will be attached to a file
            // System.Web.HttpResponse.End() function will throw System.Threading.ThreadAbortException
            // indicating that the current response ends prematurely - that's what we want
            response.End();
        }

        // Creates Excel Workbook that is used for Export to Excel request.
        protected internal void CreateExcelBook()
        {
            ISDExcelBook = new ISDWorkbook();

            ISDExcelBook.Properties.Title = Title;

            ISDExcelSheet = new ISDWorksheet("Sheet1");
            ISDExcelBook.Worksheets.Add(ISDExcelSheet);

            ISDExcelRow = new ISDWorksheetRow();
            ISDExcelSheet.Table.Rows.Add(ISDExcelRow);
        }
        #endregion
    }

    public class ExportDataToCSV : ExportToCSVBaseClass
    {
        #region "Properties"
        private DataForExport data = null;
        new public int pageSize = 5000;

        protected override string Title
        {
            get
            {
                return data.Title;
            }
        }
        #endregion

        #region "Constructor"
        private ExportDataToCSV() { } //don't use this one!

        public ExportDataToCSV(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns)
            : base()
        {
            data = new DataForExport(tbl, wc, orderBy, columns);
        }
        public ExportDataToCSV(BaseTable tbl, WhereClause wc, OrderBy orderBy)
            : base()
        {
            data = new DataForExport(tbl, wc, orderBy, null);
        }

        public ExportDataToCSV(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns, String header)
            : base(header)
        {
            data = new DataForExport(tbl, wc, orderBy, columns);
        }

        public ExportDataToCSV(BaseTable tbl, WhereClause wc, OrderBy orderBy, String header)
            : base(header)
        {
            data = new DataForExport(tbl, wc, orderBy, null);
        }
        #endregion

        #region "Private Methods"
        public string GetDataForExport(BaseColumn col, BaseRecord rec)
        {
            String val = "";

            if (col.TableDefinition.IsExpandableNonCompositeForeignKey(col))
            {
                //  Foreign Key column, so we will use DFKA and String type.
                val = rec.Format(col);
            }
            else
            {
                switch (col.ColumnType)
                {
                    case BaseColumn.ColumnTypes.Binary:
                    case BaseColumn.ColumnTypes.Image:
                        break;
                    case BaseColumn.ColumnTypes.Currency:
                    case BaseColumn.ColumnTypes.Number:
                    case BaseColumn.ColumnTypes.Percentage:
                        val = rec.Format(col);
                        break;
                    default:
                        val = rec.Format(col);
                        break;
                }
            }
            return val;
        }



        protected override bool WriteColumnHeader(bool exportRawValues)
        {
            if (base.WriteColumnHeader(exportRawValues))
                return true;

            //  If DisplayString is null, then write out the Column's name property as the header.
            foreach (BaseColumn col in data.ColumnList)
            {
                if (!(col == null))
                {
                    if (data.IncludeInExport(col))
                    {
                        if (!exportRawValues )
                            base.WriteColumnTitle(col.Name);
                        else
                             {
                            Boolean _isExpandableNonCompositeForeignKey = col.TableDefinition.IsExpandableNonCompositeForeignKey(col);
                            if (_isExpandableNonCompositeForeignKey)
                            {
                                ForeignKey fkColumn = data.DBTable.TableDefinition.GetExpandableNonCompositeForeignKey(col);
                                String name = fkColumn.GetPrimaryKeyColumnName(col);
                                base.WriteColumnTitle(name);
                            }
                            else
                                base.WriteColumnTitle(col.Name);
                        }
                    }
                }
            }
            return true;
        }

        protected void WriteRows()
        {
            bool done = false;

            int totalRowsReturned = 0;
            //  Read pageSize records at a time and write out the CSV file.
            while (!done)
            {
                ArrayList recList = data.GetRows(pageSize);
                if (recList == null)
                    break; //we are done

                totalRowsReturned = recList.Count;
                foreach (BaseRecord rec in recList)
                {
                    foreach (BaseColumn col in data.ColumnList)
                    {
                        if (col == null)
                            continue;

                        if (!data.IncludeInExport(col))
                            continue;

                        String val = GetDataForExport(col, rec);

                        base.WriteColumnData(val, data.IsString(col));
                    }
                    base.WriteNewRow();
                }

                //  If we already are below the pageSize, then we are done.
                if ((totalRowsReturned < pageSize))
                {
                    done = true;
                }
            }
        }

        #endregion

        #region "Public Methods"
        public override void Export(System.Web.HttpResponse response)
        {
            if (response == null)
                return;

            StartExport(response, false);
            WriteRows();
            FinishExport(response);
        }
        #endregion
    }
    
    /// <summary>
    /// The ExportDataToExcel class exports to Excel file and sends the XLS file to the response stream.
    /// </summary>
    public class ExportDataToExcel : ExportToExcelBaseClass
    {
        #region "Properties"
        private DataForExport data = null;
        new public int pageSize = 5000;

        protected override string Title
        {
            get
            {
                return data.Title;
            }
        }

        #endregion

        #region "Constructor"
        private ExportDataToExcel() { } //don't use this one!

        public ExportDataToExcel(BaseTable tbl, WhereClause wc, OrderBy orderBy)
            : base()
        {
            data = new DataForExport(tbl, wc, orderBy, null);
        }
        #endregion

        #region "Private Methods"

        public string GetDisplayFormat(ExcelColumn col)
        {
            return col.DisplayFormat;
        }

        //return true if type can be included in export data
        protected internal ISDDataType GetExcelDataType(ExcelColumn col)
        {
            if (col.DisplayColumn.TableDefinition.IsExpandableNonCompositeForeignKey(col.DisplayColumn))
                return ISDDataType.ISDString;
                      
            switch (col.DisplayColumn.ColumnType)
            {
                case BaseColumn.ColumnTypes.Number:
                case BaseColumn.ColumnTypes.Percentage:
                    return ISDDataType.ISDNumber;

                case BaseColumn.ColumnTypes.Currency:
                    return ISDDataType.ISDNumber;

                case BaseColumn.ColumnTypes.Date:
                    return ISDDataType.ISDDateTime;

                case BaseColumn.ColumnTypes.Very_Large_String:
                    return ISDDataType.ISDString;

                case BaseColumn.ColumnTypes.Boolean:
                    return ISDDataType.ISDString;

                default:
                    return ISDDataType.ISDString;
            }
        }

        public int GetExcelCellWidth(ExcelColumn col)
        {
            if (col == null)
                return 0;

            int width = 50;
            if (col.DisplayColumn.TableDefinition.IsExpandableNonCompositeForeignKey(col.DisplayColumn))
            {
                // Set width if field is a foreign key field
                width = 100;
            }
            else
            {
                switch (col.DisplayColumn.ColumnType)
                {
                    case BaseColumn.ColumnTypes.Binary:
                    case BaseColumn.ColumnTypes.Image:
                        //  Skip - do nothing for these columns
                        width = 0;
                        break;
                    case BaseColumn.ColumnTypes.Currency:
                    case BaseColumn.ColumnTypes.Number:
                    case BaseColumn.ColumnTypes.Percentage:
                        width = 60;
                        break;
                    case BaseColumn.ColumnTypes.String:
                        width = 255;
                        break;
                    case BaseColumn.ColumnTypes.Very_Large_String:
                        width = 255;
                        break;
                    default:
                        width = 50;
                        break;
                }
            }
            return width;
        }



protected internal object GetValueForExcelExport(ExcelColumn col, BaseRecord rec)
{
	object val = "";
	bool isNull = false;
	decimal deciNumber = default(decimal);

	if (col == null) {
		return null;
	}
	//DFKA value is evaluated in the <tablename>ExportExcelButton_Click method in the <tablename>.controls file
	//if (col.DisplayColumn.TableDefinition.IsExpandableNonCompositeForeignKey(col.DisplayColumn))
	//{
	//    //  Foreign Key column, so we will use DFKA and String type.
	//    val = rec.Format(col.DisplayColumn);
	//}
	//else
	//{
	switch (col.DisplayColumn.ColumnType) {

		case BaseColumn.ColumnTypes.Number:
		case BaseColumn.ColumnTypes.Percentage:
		case BaseColumn.ColumnTypes.Currency:
			ColumnValue numVal = rec.GetValue(col.DisplayColumn);

			//If the value of the column to be exported is nothing, add an empty cell to the Excel file
			if (numVal.IsNull) {
				isNull = true;
			} else {
				deciNumber = numVal.ToDecimal();
				val = deciNumber;








			}

			break;
		case BaseColumn.ColumnTypes.Date:
			ColumnValue dateVal = rec.GetValue(col.DisplayColumn);
			if (dateVal.IsNull) {
				isNull = true;
			} else {
				// Specify the default Excel format for the date field 
				// val = rec.Format(col.DisplayColumn, "s");
				// val += ".000";
				val = rec.GetValue(col.DisplayColumn).Value;
			}

			break;
		case BaseColumn.ColumnTypes.Very_Large_String:
			val = rec.GetValue(col.DisplayColumn).ToString();


			break;
		case BaseColumn.ColumnTypes.Boolean:
			val = rec.Format(col.DisplayColumn);

			break;
		default:

			val = rec.Format(col.DisplayColumn);

			break;
	}
	//}
	if (isNull) {
		return null;
	} else {
		return val;
	}
}
        #endregion

        #region "Public Methods"
        public void AddColumn(ExcelColumn col)
        {
            data.ColumnList.Add(col);
        }

        public override void Export(System.Web.HttpResponse response)
        {
            bool done = false;
            object val;

            if (response == null)
                return;

            CreateExcelBook();

            int width = 0;
            int columnCounter = 0;

            //  First write out the Column Headers
            foreach (ExcelColumn col in data.ColumnList)
            {
                width = GetExcelCellWidth(col);
                if (data.IncludeInExport(col))
                {
                    AddColumnToExcelBook(columnCounter, col.ToString(), GetExcelDataType(col), width, GetDisplayFormat(col));
                    columnCounter++;
                }
            }
            // Read pageSize records at a time and write out the Excel file.
            int totalRowsReturned = 0;

            while (!done)
            {
                ArrayList recList = data.GetRows(pageSize);

                if (recList == null)
                {
                    break;
                }
                totalRowsReturned = recList.Count;

                foreach (BaseRecord rec in recList)
                {
                    AddRowToExcelBook();
                    columnCounter = 0;
                    foreach (ExcelColumn col in data.ColumnList)
                    {
                        if (!data.IncludeInExport(col))
                            continue;

                        val = GetValueForExcelExport(col, rec);
                        AddCellToExcelRow(columnCounter, GetExcelDataType(col), val, col.DisplayFormat);

                        columnCounter++;
                    }
                }

                // If we already are below the pageSize, then we are done.
                if ((totalRowsReturned < pageSize))
                {
                    done = true;
                }
            }

            SaveExcelBook(response);
        }
        #endregion

    }

    /// <summary>
    /// The DataForExport class is a support class for Exportdata.
    /// It encapsulate access to data needs to be exported:
    /// data rows, title, columns.
    /// </summary>
    class DataForExport
    {
        public ArrayList ColumnList = new ArrayList();

        public BaseTable _tbl;
        public BaseTable DBTable
        {
            get { return _tbl; }
            set { _tbl = value; }
        }

        public WhereClause _wc;
        public WhereClause SelectWhereClause
        {
            get { return _wc; }
            set { _wc = value; }
        }

        public OrderBy _orderby;
        public OrderBy SelectOrderBy
        {
            get { return _orderby; }
            set { _orderby = value; }
        }

        public BaseFilter _join;
        public BaseFilter SelectJoin
        {
            get
            {    return _join; }
            
            set{_join = value;}
        }

        public string Title
        {
            get
            {
                if (DBTable.TableDefinition == null)
                    return "Unnamed";

                return DBTable.TableDefinition.Name;
            }
        }

        int pageIndex = 0;
        public ArrayList GetRows(int pageSize)
        {

            int totalRows = 0;

            ArrayList recList = null;

            //  Read pageSize records at a time and write out the CSV file.
            if (SelectWhereClause.RunQuery)
            {
                recList = DBTable.GetRecordList(SelectJoin, SelectWhereClause.GetFilter(), null, SelectOrderBy, pageIndex, pageSize, ref totalRows);
                pageIndex++;
            }

            return recList;
        }


        public DataForExport(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns)
        {
            this.DBTable = tbl;
            this.SelectWhereClause = wc;
            this.SelectOrderBy = orderBy;
            this.SelectJoin = null;
            if (columns != null)
                ColumnList.AddRange(columns);
        }

         public DataForExport(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns, BaseFilter join)
        {
            this.DBTable = tbl;
            this.SelectWhereClause = wc;
            this.SelectOrderBy = orderBy;
            this.SelectJoin = join;
            if (columns != null)
                ColumnList.AddRange(columns);
        }

        public bool IsString(BaseColumn col)
        {
            if (col == null)
                return false;

            switch (col.ColumnType)
            {
                case BaseColumn.ColumnTypes.Binary:
                case BaseColumn.ColumnTypes.Image:
                case BaseColumn.ColumnTypes.Currency:
                case BaseColumn.ColumnTypes.Number:
                case BaseColumn.ColumnTypes.Percentage:
                    return false;
            }
            return true;
        }
        public bool IsString(ExcelColumn col)
        {
            if (col == null)
                return false;

            return IsString(col.DisplayColumn);
        }

        public bool IncludeInExport(BaseColumn col)
        {
            if (col == null)
                return false;

            switch (col.ColumnType)
            {
                case BaseColumn.ColumnTypes.Binary:
                case BaseColumn.ColumnTypes.Image:
                    //  Skip - do nothing for these columns
                    return false;
            }
            return true;
        }

        public bool IncludeInExport(ExcelColumn col)
        {
            if (col == null)
                return false;

            return IncludeInExport(col.DisplayColumn);
        }
    }
        /// <summary>
        /// ExcelColumn class is used to set Excel format for BaseClolumn to be used for exporting data to Excel file.
        /// </summary>
        public class ExcelColumn
        {

            #region "Constructor"
            /// <summary>
            /// Cretes new ExcelColumn
            /// </summary>
            /// <param name="col">BaseColumn</param>
            /// <param name="format">a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"</param>
            public ExcelColumn(BaseColumn col, string format)
            {
                DisplayColumn = col;
                DisplayFormat = format;
            }
            #endregion
            #region "Properties"
            private BaseColumn _column;
            public BaseColumn DisplayColumn
            {
                get { return _column; }
                set { _column = value; }
            }

            private string _format;
            public string DisplayFormat
            {
                get { return _format; }
                set { _format = value; }
            }
            #endregion

            #region "Public Methods"
            public override string ToString()
            {
                return DisplayColumn.Name;
            }
            #endregion
        }


        /// <summary>
        /// This class is redundant. It is left here for backward compatibility.
        /// </summary>
        /// <remarks></remarks>
        public class ExportData
        {
            #region "Private members"
            private ExportDataToCSV _exportDataToCSV = null;
            private ExportDataToExcel _exportDataToExcel = null;
            #endregion

            #region "Constructor"
            public ExportData(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns)
            {
                _exportDataToCSV = new ExportDataToCSV(tbl, wc, orderBy, columns);
            }

            public ExportData(BaseTable tbl, WhereClause wc, OrderBy orderBy)
            {
                _exportDataToCSV = new ExportDataToCSV(tbl, wc, orderBy);
                _exportDataToExcel = new ExportDataToExcel(tbl, wc, orderBy);
            }

            public ExportData(BaseTable tbl, WhereClause wc, OrderBy orderBy, BaseColumn[] columns, String header)
            {
                _exportDataToCSV = new ExportDataToCSV(tbl, wc, orderBy, columns, header);
            }
            #endregion
            public void AddColumn(ExcelColumn col)
            {
                if (_exportDataToExcel != null)
                    _exportDataToExcel.AddColumn(col);
            }
            public void ExportToCSV(System.Web.HttpResponse response)
            {
                if ( _exportDataToCSV != null)
                    _exportDataToCSV.Export(response);
            }
            public void ExportToExcel(System.Web.HttpResponse response)
            {
                if (_exportDataToExcel != null)
                    _exportDataToExcel.Export(response);
            }
        }
}

