using System;
using System.IO;
using BaseClasses.Utils;
using BaseClasses.Data;

namespace VPLookup
{
    public partial class ExportFieldValue : VPLookup.UI.BaseApplicationPage
    {

        [System.Diagnostics.DebuggerStepThrough()]
        private void InitializeComponent()
        {
        }

        private void Page_Init(object sender, System.EventArgs e)
        {
            InitializeComponent();
        }
          

        public string FieldId
        {
            get
            {
                return this.Decrypt(this.Request.Params["Field"]);
            }
        }

        public string FileName
        {
            get
            {
                string fn = this.Request.Params["FileName"];
                try
                {
                    // Try to decrypt
                    return this.Decrypt(fn);
                }
                catch
                {
                    // For backward compatibility we support unencrypted version as well
                    return fn;
                }
            }
        }
        
        public string RecordId
        {
            get
            {
                return this.Decrypt(this.Request.Params["Record"]);
            }
        }

        public string TableId
        {
            get
            {
                string tableName = ((string)this.Request.Params["Table"]);
                if (string.IsNullOrEmpty(tableName)) return "";
                tableName = this.Decrypt(tableName);
                return tableName;
            }
        }

        public int Offset
        {
            get
            {
                if (this.Request.Params["Offset"] != null)
                {
                    return System.Convert.ToInt32(this.Request.Params["Offset"]);
                }
                else
                {
                    return 0;
                }
            }
        }

        public int ImageHeight
        {
            get
            {
                if (this.Request.Params["ImageHeight"] != null)
                {
                    return int.Parse(this.Request.Params["ImageHeight"]);
                }
                else
                {
                    return 0;
                }
            }
        }

        public int ImageWidth
        {
            get
            {
                if (this.Request.Params["ImageWidth"] != null)
                {
                    return int.Parse(this.Request.Params["ImageWidth"]);
                }
                else
                {
                    return 0;
                }
            }
        }

        public double ImagePercentSize
        {
			get
			{
				if (this.Request.Params["ImagePercentSize"] != null)
				{
					return double.Parse(this.Request.Params["ImagePercentSize"]);
				}
				else
				{
					return 0.0;
				}
			}
        }

        public ExportFieldValue()
        {
            this.Load += new EventHandler(Page_Load);
        }

        private void Page_Load(object sender, System.EventArgs e)
        {
            if ((BaseClasses.Utils.NetUtils.GetUrlParam(this, "Table", true) == null) ||
                (BaseClasses.Utils.NetUtils.GetUrlParam(this, "Table", true).Length == 0) ||
                (BaseClasses.Utils.NetUtils.GetUrlParam(this, "Record", true) == null) ||
                (BaseClasses.Utils.NetUtils.GetUrlParam(this, "Record", true).Length == 0) ||
                (BaseClasses.Utils.NetUtils.GetUrlParam(this, "Field", true) == null) ||
                (BaseClasses.Utils.NetUtils.GetUrlParam(this, "Field", true).Length == 0))
            {
                return;
            }
            this.DataBind();
            this.ExportData();
        }

        protected void ExportData()
        {
            if (string.IsNullOrEmpty(this.TableId)) return;
            try
            {
                PrimaryKeyTable t = (PrimaryKeyTable)DatabaseObjects.GetTableObject(this.TableId);
                BaseRecord rec = (BaseRecord)t.GetRecordData(this.RecordId, false);
                if ((this.ImagePercentSize != 100.0 && !(this.ImagePercentSize == 0.0)) || !((this.ImageHeight == 0) || (this.ImageWidth == 0)))
                {
					//To display image with shrinking according to user specified height/width or ImagePercentSize
                    ColumnValue fieldData = MiscUtils.GetData(rec, t.TableDefinition.ColumnList.GetByAnyName(this.FieldId));
                    byte[] binaryData = MiscUtils.GetBinaryData(t.TableDefinition.ColumnList.GetByAnyName(this.FieldId), fieldData);
                    if(binaryData == null || binaryData.Length == 0)
                    {
                        MiscUtils.RegisterJScriptAlert(this, "No Content", "Field " + this.FieldId + " does not contain any binary data.", false, true);
                         return;
                    }
                    byte[] thumbNailSizeImage = GetThumbNailSizeImage(binaryData);
                    string filName = MiscUtils.GetFileNameWithExtension(t.TableDefinition.ColumnList.GetByAnyName(this.FieldId), binaryData, null);
                    MiscUtils.SendToWriteResponse(this.Response, thumbNailSizeImage, filName, t.TableDefinition.ColumnList.GetByAnyName(this.FieldId), fieldData, this.Offset);
                }
                else
                {
					//Calling ExportFieldData method without image shrinking.
	                if(!MiscUtils.ExportFieldData(this.Response, rec, t.TableDefinition.ColumnList.GetByAnyName(this.FieldId), this.FileName, this.Offset))
                    {
                        MiscUtils.RegisterJScriptAlert(this, "No Content", "Field " + this.FieldId + " does not contain any binary data.", false, true);
                        return;
                    }
                }
            }
            catch 
            {
            }
        }

        protected byte[] GetThumbNailSizeImage(byte[] binaryData)
        {
            byte[] ThumbNailBinaryData=null;
            try
            {
                System.IO.MemoryStream TempMemStream = new System.IO.MemoryStream(binaryData);
                System.Drawing.Image ImageObj;
                System.Drawing.Image ThumbSizeImageObj;
                ImageObj = System.Drawing.Image.FromStream(TempMemStream);
				int temHeight;
				int temWidth;
				temHeight = ImageObj.Height;
				temWidth = ImageObj.Width;
                System.IO.MemoryStream TempFileStream = new System.IO.MemoryStream();
				// If Imagesize is less than 20*20 then return the original image
				if (((temWidth < 20) 
					&& (temHeight < 20))) 
				{
					byte[] ImageBinaryData;
                    try
                    {
                        //load as raw format so that the image can have transparency is retained.
                        ImageObj.Save(TempFileStream, ImageObj.RawFormat);
                    }
                    catch
                    {
                        //if exception happens which can be for .ico, then load as jpeg but transparency cannot be retained.
                        ImageObj.Save(TempFileStream, System.Drawing.Imaging.ImageFormat.Jpeg);
                    }
					ImageBinaryData = new byte[] {((byte)(TempFileStream.Length))};
					ImageBinaryData = TempFileStream.ToArray();
					return ImageBinaryData;
				}
				double percentSize = this.ImagePercentSize;
				 
                // If the ImagePercentSize is 0.2 then the actual percent calculation will result in generating
                // temHeight and temWidth as Zero. When the height and width is zero, GetThumbnailImage() 
                // will generate image of arbitrary size. Hence the image will not display as predicted, 
                // ie, with size 0.2%. For this purpose, to maintain consistant image size, when ImagePercentSize 
                // is less than 1, it is taken as actual percentage for eg. when ImagePercentSize is 0.2, it is considered as 20%
                // and image will displayed with 20% of original size.
                if (this.ImagePercentSize <= 1)
				{ 
					percentSize = this.ImagePercentSize * 100;
				}
                //Actual percentage calculation. as ImagePercentSize value provided by client is a number not a percent
                percentSize = percentSize / 100;
				temHeight = (int)((percentSize * temHeight));
				temWidth = (int)((percentSize * temWidth));
				// Create thumbnail size of the original Image ImageObj
				if (this.ImagePercentSize == 0) 
				{
					ThumbSizeImageObj = ImageObj.GetThumbnailImage(this.ImageWidth, this.ImageHeight, null, IntPtr.Zero);
				}
				else 
				{
					ThumbSizeImageObj = ImageObj.GetThumbnailImage(temWidth, temHeight, null, IntPtr.Zero);
				}
                try
                {
                    //load as raw format so that the image can have transparency is retained.
                    ThumbSizeImageObj.Save(TempFileStream, ImageObj.RawFormat);
                }
                catch
                {
                    //if exception happens which can be for .ico, then load as jpeg but transparency cannot be retained.
                    ThumbSizeImageObj.Save(TempFileStream, System.Drawing.Imaging.ImageFormat.Jpeg);
                }
                ThumbNailBinaryData = new byte[] {
                    ((byte)(TempFileStream.Length))};
                ThumbNailBinaryData = TempFileStream.ToArray();
            }
            catch 
            {
            }
            return ThumbNailBinaryData;
        }
         
        protected override void UpdateSessionNavigationHistory()
        {
        }
    }
}