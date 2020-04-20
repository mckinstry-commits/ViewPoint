namespace McKinstry.Viewpoint.APImport
{
    partial class APImportForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.grpSelectBatch = new System.Windows.Forms.GroupBox();
            this.lblChooseFileCaption = new System.Windows.Forms.Label();
            this.cboBatches = new System.Windows.Forms.ComboBox();
            this.lblSelectBatch = new System.Windows.Forms.Label();
            this.grpUploadBatch = new System.Windows.Forms.GroupBox();
            this.lblArchive = new System.Windows.Forms.Label();
            this.lblArchiveCaption = new System.Windows.Forms.Label();
            this.lblProcessDateCaption = new System.Windows.Forms.Label();
            this.lblFileSizeCaption = new System.Windows.Forms.Label();
            this.lblFileNameCaption = new System.Windows.Forms.Label();
            this.lblProcessDate = new System.Windows.Forms.Label();
            this.lblFileSize = new System.Windows.Forms.Label();
            this.btnUpload = new System.Windows.Forms.Button();
            this.lblFileName = new System.Windows.Forms.Label();
            this.btnClose = new System.Windows.Forms.Button();
            this.lblProgress = new System.Windows.Forms.Label();
            this.grpSelectBatch.SuspendLayout();
            this.grpUploadBatch.SuspendLayout();
            this.SuspendLayout();
            // 
            // grpSelectBatch
            // 
            this.grpSelectBatch.AutoSize = true;
            this.grpSelectBatch.Controls.Add(this.lblChooseFileCaption);
            this.grpSelectBatch.Controls.Add(this.cboBatches);
            this.grpSelectBatch.Controls.Add(this.lblSelectBatch);
            this.grpSelectBatch.Location = new System.Drawing.Point(59, 25);
            this.grpSelectBatch.Name = "grpSelectBatch";
            this.grpSelectBatch.Size = new System.Drawing.Size(468, 107);
            this.grpSelectBatch.TabIndex = 0;
            this.grpSelectBatch.TabStop = false;
            this.grpSelectBatch.Text = "Select AP Import File";
            // 
            // lblChooseFileCaption
            // 
            this.lblChooseFileCaption.AutoSize = true;
            this.lblChooseFileCaption.Location = new System.Drawing.Point(38, 72);
            this.lblChooseFileCaption.Name = "lblChooseFileCaption";
            this.lblChooseFileCaption.Size = new System.Drawing.Size(312, 13);
            this.lblChooseFileCaption.TabIndex = 2;
            this.lblChooseFileCaption.Text = "Select AP unapproved invoice  import file to upload to Viewpoint.";
            // 
            // cboBatches
            // 
            this.cboBatches.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboBatches.FormattingEnabled = true;
            this.cboBatches.Location = new System.Drawing.Point(78, 37);
            this.cboBatches.Name = "cboBatches";
            this.cboBatches.Size = new System.Drawing.Size(334, 21);
            this.cboBatches.TabIndex = 1;
            this.cboBatches.SelectedIndexChanged += new System.EventHandler(this.cboBatches_SelectedIndexChanged);
            // 
            // lblSelectBatch
            // 
            this.lblSelectBatch.AutoSize = true;
            this.lblSelectBatch.Location = new System.Drawing.Point(16, 40);
            this.lblSelectBatch.Name = "lblSelectBatch";
            this.lblSelectBatch.Size = new System.Drawing.Size(58, 13);
            this.lblSelectBatch.TabIndex = 0;
            this.lblSelectBatch.Text = "Import File:";
            // 
            // grpUploadBatch
            // 
            this.grpUploadBatch.AutoSize = true;
            this.grpUploadBatch.Controls.Add(this.lblArchive);
            this.grpUploadBatch.Controls.Add(this.lblArchiveCaption);
            this.grpUploadBatch.Controls.Add(this.lblProcessDateCaption);
            this.grpUploadBatch.Controls.Add(this.lblFileSizeCaption);
            this.grpUploadBatch.Controls.Add(this.lblFileNameCaption);
            this.grpUploadBatch.Controls.Add(this.lblProcessDate);
            this.grpUploadBatch.Controls.Add(this.lblFileSize);
            this.grpUploadBatch.Controls.Add(this.btnUpload);
            this.grpUploadBatch.Controls.Add(this.lblFileName);
            this.grpUploadBatch.Location = new System.Drawing.Point(59, 148);
            this.grpUploadBatch.Name = "grpUploadBatch";
            this.grpUploadBatch.Size = new System.Drawing.Size(468, 162);
            this.grpUploadBatch.TabIndex = 1;
            this.grpUploadBatch.TabStop = false;
            this.grpUploadBatch.Text = "Import File Details";
            // 
            // lblArchive
            // 
            this.lblArchive.AutoSize = true;
            this.lblArchive.Location = new System.Drawing.Point(99, 60);
            this.lblArchive.Name = "lblArchive";
            this.lblArchive.Size = new System.Drawing.Size(53, 13);
            this.lblArchive.TabIndex = 8;
            this.lblArchive.Text = "lblArchive";
            // 
            // lblArchiveCaption
            // 
            this.lblArchiveCaption.AutoSize = true;
            this.lblArchiveCaption.Location = new System.Drawing.Point(19, 60);
            this.lblArchiveCaption.Name = "lblArchiveCaption";
            this.lblArchiveCaption.Size = new System.Drawing.Size(46, 13);
            this.lblArchiveCaption.TabIndex = 7;
            this.lblArchiveCaption.Text = "Archive:";
            // 
            // lblProcessDateCaption
            // 
            this.lblProcessDateCaption.AutoSize = true;
            this.lblProcessDateCaption.Location = new System.Drawing.Point(19, 90);
            this.lblProcessDateCaption.Name = "lblProcessDateCaption";
            this.lblProcessDateCaption.Size = new System.Drawing.Size(60, 13);
            this.lblProcessDateCaption.TabIndex = 6;
            this.lblProcessDateCaption.Text = "Processed:";
            // 
            // lblFileSizeCaption
            // 
            this.lblFileSizeCaption.AutoSize = true;
            this.lblFileSizeCaption.Location = new System.Drawing.Point(19, 120);
            this.lblFileSizeCaption.Name = "lblFileSizeCaption";
            this.lblFileSizeCaption.Size = new System.Drawing.Size(49, 13);
            this.lblFileSizeCaption.TabIndex = 5;
            this.lblFileSizeCaption.Text = "File Size:";
            // 
            // lblFileNameCaption
            // 
            this.lblFileNameCaption.AutoSize = true;
            this.lblFileNameCaption.Location = new System.Drawing.Point(19, 30);
            this.lblFileNameCaption.Name = "lblFileNameCaption";
            this.lblFileNameCaption.Size = new System.Drawing.Size(57, 13);
            this.lblFileNameCaption.TabIndex = 4;
            this.lblFileNameCaption.Text = "File Name:";
            // 
            // lblProcessDate
            // 
            this.lblProcessDate.AutoSize = true;
            this.lblProcessDate.Location = new System.Drawing.Point(99, 90);
            this.lblProcessDate.Name = "lblProcessDate";
            this.lblProcessDate.Size = new System.Drawing.Size(78, 13);
            this.lblProcessDate.TabIndex = 3;
            this.lblProcessDate.Text = "lblProcessDate";
            // 
            // lblFileSize
            // 
            this.lblFileSize.AutoSize = true;
            this.lblFileSize.Location = new System.Drawing.Point(99, 120);
            this.lblFileSize.Name = "lblFileSize";
            this.lblFileSize.Size = new System.Drawing.Size(53, 13);
            this.lblFileSize.TabIndex = 2;
            this.lblFileSize.Text = "lblFileSize";
            // 
            // btnUpload
            // 
            this.btnUpload.Location = new System.Drawing.Point(364, 120);
            this.btnUpload.Name = "btnUpload";
            this.btnUpload.Size = new System.Drawing.Size(75, 23);
            this.btnUpload.TabIndex = 1;
            this.btnUpload.Text = "Upload";
            this.btnUpload.UseVisualStyleBackColor = true;
            this.btnUpload.Click += new System.EventHandler(this.btnUpload_Click);
            // 
            // lblFileName
            // 
            this.lblFileName.AutoSize = true;
            this.lblFileName.Location = new System.Drawing.Point(99, 31);
            this.lblFileName.Name = "lblFileName";
            this.lblFileName.Size = new System.Drawing.Size(61, 13);
            this.lblFileName.TabIndex = 0;
            this.lblFileName.Text = "lblFileName";
            // 
            // btnClose
            // 
            this.btnClose.Location = new System.Drawing.Point(452, 345);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(75, 23);
            this.btnClose.TabIndex = 9;
            this.btnClose.Text = "Close";
            this.btnClose.UseVisualStyleBackColor = true;
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // lblProgress
            // 
            this.lblProgress.AutoSize = true;
            this.lblProgress.Location = new System.Drawing.Point(56, 334);
            this.lblProgress.Name = "lblProgress";
            this.lblProgress.Size = new System.Drawing.Size(0, 13);
            this.lblProgress.TabIndex = 10;
            // 
            // APImportForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSize = true;
            this.ClientSize = new System.Drawing.Size(585, 391);
            this.Controls.Add(this.lblProgress);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.grpUploadBatch);
            this.Controls.Add(this.grpSelectBatch);
            this.Name = "APImportForm";
            this.Text = "AP Unapproved Invoice Import";
            this.Load += new System.EventHandler(this.APImportForm_Load);
            this.grpSelectBatch.ResumeLayout(false);
            this.grpSelectBatch.PerformLayout();
            this.grpUploadBatch.ResumeLayout(false);
            this.grpUploadBatch.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.GroupBox grpSelectBatch;
        private System.Windows.Forms.Label lblSelectBatch;
        private System.Windows.Forms.ComboBox cboBatches;
        private System.Windows.Forms.GroupBox grpUploadBatch;
        private System.Windows.Forms.Label lblFileName;
        private System.Windows.Forms.Button btnUpload;
        private System.Windows.Forms.Label lblFileSize;
        private System.Windows.Forms.Label lblProcessDate;
        private System.Windows.Forms.Label lblProcessDateCaption;
        private System.Windows.Forms.Label lblFileSizeCaption;
        private System.Windows.Forms.Label lblFileNameCaption;
        private System.Windows.Forms.Label lblArchive;
        private System.Windows.Forms.Label lblArchiveCaption;
        private System.Windows.Forms.Label lblChooseFileCaption;
        private System.Windows.Forms.Button btnClose;
        private System.Windows.Forms.Label lblProgress;
    }
}