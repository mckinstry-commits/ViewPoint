namespace McK.PRMyTimesheet.Viewpoint
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ActionPane
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.btnGetTimesheets = new System.Windows.Forms.Button();
            this.btnBatchApprvTimesheets = new System.Windows.Forms.Button();
            this.lblVersion = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.txtEndDate = new System.Windows.Forms.MaskedTextBox();
            this.txtStartDate = new System.Windows.Forms.MaskedTextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.cboPRGroup = new System.Windows.Forms.ComboBox();
            this.label5 = new System.Windows.Forms.Label();
            this.lblDayOfWeek = new System.Windows.Forms.Label();
            this.chkBatched = new System.Windows.Forms.CheckBox();
            this.txtInclPaySeq = new System.Windows.Forms.TextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.txtExclPaySeq = new System.Windows.Forms.TextBox();
            this.btnCopyWkbOffline = new System.Windows.Forms.Button();
            this.lblEnvironment = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.SuspendLayout();
            // 
            // pictureBox1
            // 
            this.pictureBox1.Image = global::McK.PRMyTimesheet.Viewpoint.Properties.Resources.McKinstry_Logo_Sm;
            this.pictureBox1.Location = new System.Drawing.Point(3, 3);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(100, 50);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.pictureBox1.TabIndex = 0;
            this.pictureBox1.TabStop = false;
            // 
            // btnGetTimesheets
            // 
            this.btnGetTimesheets.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F);
            this.btnGetTimesheets.Location = new System.Drawing.Point(6, 457);
            this.btnGetTimesheets.Name = "btnGetTimesheets";
            this.btnGetTimesheets.Size = new System.Drawing.Size(97, 41);
            this.btnGetTimesheets.TabIndex = 4;
            this.btnGetTimesheets.Text = "Get Timesheets";
            this.btnGetTimesheets.UseVisualStyleBackColor = true;
            this.btnGetTimesheets.Click += new System.EventHandler(this.btnGetTimesheets_Click);
            this.btnGetTimesheets.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            // 
            // btnBatchApprvTimesheets
            // 
            this.btnBatchApprvTimesheets.Enabled = false;
            this.btnBatchApprvTimesheets.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F);
            this.btnBatchApprvTimesheets.Location = new System.Drawing.Point(5, 508);
            this.btnBatchApprvTimesheets.Name = "btnBatchApprvTimesheets";
            this.btnBatchApprvTimesheets.Size = new System.Drawing.Size(97, 56);
            this.btnBatchApprvTimesheets.TabIndex = 5;
            this.btnBatchApprvTimesheets.Text = "Batch Approved Timesheets";
            this.btnBatchApprvTimesheets.UseVisualStyleBackColor = true;
            this.btnBatchApprvTimesheets.Click += new System.EventHandler(this.btnBatchApprvTimesheets_Click);
            // 
            // lblVersion
            // 
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(5, 72);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(103, 12);
            this.lblVersion.TabIndex = 42;
            this.lblVersion.Text = "v1.0.0.0";
            this.lblVersion.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(-1, 54);
            this.label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(118, 18);
            this.label2.TabIndex = 43;
            this.label2.Text = "PR My Timesheet";
            this.label2.UseMnemonic = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(11, 122);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(82, 15);
            this.label1.TabIndex = 45;
            this.label1.Text = "PR Company:";
            // 
            // cboCompany
            // 
            this.cboCompany.BackColor = System.Drawing.SystemColors.Info;
            this.cboCompany.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboCompany.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboCompany.DropDownWidth = 80;
            this.cboCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboCompany.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboCompany.FormattingEnabled = true;
            this.cboCompany.Location = new System.Drawing.Point(13, 140);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(77, 22);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboCompany.SelectedIndexChanged += new System.EventHandler(this.cboCompany_SelectedIndexChanged);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            // 
            // txtEndDate
            // 
            this.txtEndDate.BackColor = System.Drawing.SystemColors.Info;
            this.txtEndDate.Location = new System.Drawing.Point(12, 317);
            this.txtEndDate.Mask = "00/00/00";
            this.txtEndDate.Name = "txtEndDate";
            this.txtEndDate.Size = new System.Drawing.Size(75, 20);
            this.txtEndDate.TabIndex = 3;
            this.txtEndDate.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            // 
            // txtStartDate
            // 
            this.txtStartDate.BackColor = System.Drawing.SystemColors.Info;
            this.txtStartDate.Location = new System.Drawing.Point(13, 256);
            this.txtStartDate.Mask = "00/00/00";
            this.txtStartDate.Name = "txtStartDate";
            this.txtStartDate.Size = new System.Drawing.Size(74, 20);
            this.txtStartDate.TabIndex = 2;
            this.txtStartDate.TextChanged += new System.EventHandler(this.txtStartDate_TextChanged);
            this.txtStartDate.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label4.Location = new System.Drawing.Point(9, 297);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(81, 15);
            this.label4.TabIndex = 50;
            this.label4.Text = "PR End Date:";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label3.Location = new System.Drawing.Point(10, 235);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(84, 15);
            this.label3.TabIndex = 49;
            this.label3.Text = "PR Start Date:";
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // cboPRGroup
            // 
            this.cboPRGroup.BackColor = System.Drawing.SystemColors.Info;
            this.cboPRGroup.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboPRGroup.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboPRGroup.DropDownWidth = 80;
            this.cboPRGroup.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboPRGroup.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboPRGroup.FormattingEnabled = true;
            this.cboPRGroup.Location = new System.Drawing.Point(13, 194);
            this.cboPRGroup.Name = "cboPRGroup";
            this.cboPRGroup.Size = new System.Drawing.Size(74, 22);
            this.cboPRGroup.TabIndex = 1;
            this.cboPRGroup.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboBoxes_DrawItem);
            this.cboPRGroup.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tiggerEnter_KeyUp);
            this.cboPRGroup.Leave += new System.EventHandler(this.cboPRGroup_Leave);
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.Location = new System.Drawing.Point(11, 176);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(64, 15);
            this.label5.TabIndex = 52;
            this.label5.Text = "PR Group:";
            // 
            // lblDayOfWeek
            // 
            this.lblDayOfWeek.Font = new System.Drawing.Font("Microsoft Sans Serif", 6.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblDayOfWeek.Location = new System.Drawing.Point(14, 277);
            this.lblDayOfWeek.Name = "lblDayOfWeek";
            this.lblDayOfWeek.Size = new System.Drawing.Size(73, 15);
            this.lblDayOfWeek.TabIndex = 53;
            // 
            // chkBatched
            // 
            this.chkBatched.Enabled = false;
            this.chkBatched.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.chkBatched.Location = new System.Drawing.Point(7, 643);
            this.chkBatched.Margin = new System.Windows.Forms.Padding(2);
            this.chkBatched.Name = "chkBatched";
            this.chkBatched.Size = new System.Drawing.Size(95, 55);
            this.chkBatched.TabIndex = 55;
            this.chkBatched.Text = "Include Batched Timesheets";
            this.chkBatched.UseVisualStyleBackColor = true;
            // 
            // txtInclPaySeq
            // 
            this.txtInclPaySeq.BackColor = System.Drawing.SystemColors.Info;
            this.txtInclPaySeq.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtInclPaySeq.Location = new System.Drawing.Point(6, 371);
            this.txtInclPaySeq.Margin = new System.Windows.Forms.Padding(2);
            this.txtInclPaySeq.MaxLength = 1024;
            this.txtInclPaySeq.Name = "txtInclPaySeq";
            this.txtInclPaySeq.Size = new System.Drawing.Size(97, 22);
            this.txtInclPaySeq.TabIndex = 59;
            this.txtInclPaySeq.Text = "any";
            this.txtInclPaySeq.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txtInclPaySeq.TextChanged += new System.EventHandler(this.txtPaySeq_TextChanged);
            this.txtInclPaySeq.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtPaySeq_KeyDown);
            this.txtInclPaySeq.MouseLeave += new System.EventHandler(this.txtInclPaySeq_MouseLeave);
            this.txtInclPaySeq.MouseHover += new System.EventHandler(this.txtBoxPaySeq_MouseHover);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(5, 350);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(98, 15);
            this.label6.TabIndex = 60;
            this.label6.Text = "Include Pay Seq:";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label7.Location = new System.Drawing.Point(4, 403);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(102, 15);
            this.label7.TabIndex = 62;
            this.label7.Text = "Exclude Pay Seq:";
            // 
            // txtExclPaySeq
            // 
            this.txtExclPaySeq.BackColor = System.Drawing.SystemColors.Info;
            this.txtExclPaySeq.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtExclPaySeq.Location = new System.Drawing.Point(5, 423);
            this.txtExclPaySeq.Margin = new System.Windows.Forms.Padding(2);
            this.txtExclPaySeq.MaxLength = 1024;
            this.txtExclPaySeq.Name = "txtExclPaySeq";
            this.txtExclPaySeq.Size = new System.Drawing.Size(97, 22);
            this.txtExclPaySeq.TabIndex = 61;
            this.txtExclPaySeq.Text = "none";
            this.txtExclPaySeq.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txtExclPaySeq.TextChanged += new System.EventHandler(this.txtPaySeq_TextChanged);
            this.txtExclPaySeq.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtPaySeq_KeyDown);
            this.txtExclPaySeq.MouseHover += new System.EventHandler(this.txtBoxPaySeq_MouseHover);
            // 
            // btnCopyWkbOffline
            // 
            this.btnCopyWkbOffline.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F);
            this.btnCopyWkbOffline.Location = new System.Drawing.Point(6, 573);
            this.btnCopyWkbOffline.Name = "btnCopyWkbOffline";
            this.btnCopyWkbOffline.Size = new System.Drawing.Size(97, 56);
            this.btnCopyWkbOffline.TabIndex = 63;
            this.btnCopyWkbOffline.Text = "Copy Workbook Offline";
            this.btnCopyWkbOffline.UseVisualStyleBackColor = true;
            this.btnCopyWkbOffline.Click += new System.EventHandler(this.btnCopyWkbOffline_Click);
            // 
            // lblEnvironment
            // 
            this.lblEnvironment.BackColor = System.Drawing.Color.Black;
            this.lblEnvironment.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblEnvironment.ForeColor = System.Drawing.Color.Yellow;
            this.lblEnvironment.Location = new System.Drawing.Point(3, 86);
            this.lblEnvironment.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblEnvironment.Name = "lblEnvironment";
            this.lblEnvironment.Size = new System.Drawing.Size(106, 26);
            this.lblEnvironment.TabIndex = 73;
            this.lblEnvironment.Text = "(Upgrade)";
            this.lblEnvironment.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblEnvironment.UseMnemonic = false;
            // 
            // ActionPane
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.Controls.Add(this.lblEnvironment);
            this.Controls.Add(this.btnCopyWkbOffline);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.txtExclPaySeq);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.txtInclPaySeq);
            this.Controls.Add(this.chkBatched);
            this.Controls.Add(this.lblDayOfWeek);
            this.Controls.Add(this.cboPRGroup);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.txtEndDate);
            this.Controls.Add(this.txtStartDate);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.btnBatchApprvTimesheets);
            this.Controls.Add(this.btnGetTimesheets);
            this.Controls.Add(this.pictureBox1);
            this.Name = "ActionPane";
            this.Size = new System.Drawing.Size(112, 702);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.Button btnGetTimesheets;
        private System.Windows.Forms.Button btnBatchApprvTimesheets;
        internal System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.MaskedTextBox txtEndDate;
        private System.Windows.Forms.MaskedTextBox txtStartDate;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        private System.Windows.Forms.ComboBox cboPRGroup;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label lblDayOfWeek;
        private System.Windows.Forms.CheckBox chkBatched;
        private System.Windows.Forms.Button btnCopyWkbOffline;
        private System.Windows.Forms.Label label7;
        internal System.Windows.Forms.TextBox txtExclPaySeq;
        private System.Windows.Forms.Label label6;
        internal System.Windows.Forms.TextBox txtInclPaySeq;
        private System.Windows.Forms.Label lblEnvironment;
    }
}
