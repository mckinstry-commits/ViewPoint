namespace McK.GMA.Viewpoint
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ActionsPaneGMA
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
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.btnGMA = new System.Windows.Forms.Button();
            this.lblJobs = new System.Windows.Forms.Label();
            this.cboJobs = new System.Windows.Forms.ComboBox();
            this.txtViewpointContract = new System.Windows.Forms.TextBox();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.tmrUpdateButtonText = new System.Windows.Forms.Timer(this.components);
            this.lblVersion = new System.Windows.Forms.Label();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            this.lblAppName = new System.Windows.Forms.Label();
            this.lblListNoGMAs = new System.Windows.Forms.Label();
            this.tmrFadeLabel = new System.Windows.Forms.Timer(this.components);
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.lblContractName = new System.Windows.Forms.Label();
            this.txtNewContractName = new System.Windows.Forms.TextBox();
            this.btnCopyGMAoffline = new System.Windows.Forms.Button();
            this.ckbNewBlankContract = new System.Windows.Forms.CheckBox();
            this.updownJobCnt = new System.Windows.Forms.NumericUpDown();
            this.lblJobsCnt = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.updownJobCnt)).BeginInit();
            this.SuspendLayout();
            // 
            // picLogo
            // 
            this.picLogo.Image = global::McK.GMA.Viewpoint.Properties.Resources.McKinstry_Logo_Sm;
            this.picLogo.Location = new System.Drawing.Point(2, 3);
            this.picLogo.Margin = new System.Windows.Forms.Padding(2);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(63, 33);
            this.picLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picLogo.TabIndex = 4;
            this.picLogo.TabStop = false;
            // 
            // btnGMA
            // 
            this.btnGMA.Location = new System.Drawing.Point(5, 218);
            this.btnGMA.Margin = new System.Windows.Forms.Padding(2);
            this.btnGMA.Name = "btnGMA";
            this.btnGMA.Size = new System.Drawing.Size(85, 46);
            this.btnGMA.TabIndex = 6;
            this.btnGMA.Text = "Get GMA Data";
            this.btnGMA.UseVisualStyleBackColor = true;
            this.btnGMA.Click += new System.EventHandler(this.btnGMA_Click);
            this.btnGMA.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnGMA_KeyUp);
            // 
            // lblJobs
            // 
            this.lblJobs.AutoSize = true;
            this.lblJobs.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblJobs.Location = new System.Drawing.Point(3, 43);
            this.lblJobs.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblJobs.Name = "lblJobs";
            this.lblJobs.Size = new System.Drawing.Size(54, 15);
            this.lblJobs.TabIndex = 19;
            this.lblJobs.Text = "Projects:";
            // 
            // cboJobs
            // 
            this.cboJobs.DropDownHeight = 109;
            this.cboJobs.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboJobs.FormattingEnabled = true;
            this.cboJobs.IntegralHeight = false;
            this.cboJobs.ItemHeight = 15;
            this.cboJobs.Location = new System.Drawing.Point(5, 60);
            this.cboJobs.Margin = new System.Windows.Forms.Padding(2);
            this.cboJobs.MaxLength = 12;
            this.cboJobs.Name = "cboJobs";
            this.cboJobs.Size = new System.Drawing.Size(89, 23);
            this.cboJobs.TabIndex = 2;
            this.cboJobs.SelectedIndexChanged += new System.EventHandler(this.cboJobs_SelectedIndexChanged);
            this.cboJobs.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboJobs_KeyUp);
            // 
            // txtViewpointContract
            // 
            this.txtViewpointContract.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtViewpointContract.Location = new System.Drawing.Point(5, 15);
            this.txtViewpointContract.Margin = new System.Windows.Forms.Padding(2);
            this.txtViewpointContract.MaxLength = 10;
            this.txtViewpointContract.Name = "txtViewpointContract";
            this.txtViewpointContract.Size = new System.Drawing.Size(89, 21);
            this.txtViewpointContract.TabIndex = 1;
            this.txtViewpointContract.KeyUp += new System.Windows.Forms.KeyEventHandler(this.txtBoxContract_KeyUp);
            this.txtViewpointContract.Leave += new System.EventHandler(this.txtBoxContract_Leave);
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // tmrUpdateButtonText
            // 
            this.tmrUpdateButtonText.Interval = 500;
            this.tmrUpdateButtonText.Tick += new System.EventHandler(this.tmrUpdateButtonText_Tick);
            // 
            // lblVersion
            // 
            this.lblVersion.Location = new System.Drawing.Point(69, 21);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(42, 15);
            this.lblVersion.TabIndex = 20;
            this.lblVersion.Text = "v1.1.1.2";
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // lblAppName
            // 
            this.lblAppName.AutoSize = true;
            this.lblAppName.BackColor = System.Drawing.Color.Transparent;
            this.lblAppName.Location = new System.Drawing.Point(67, 3);
            this.lblAppName.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblAppName.Name = "lblAppName";
            this.lblAppName.Size = new System.Drawing.Size(27, 13);
            this.lblAppName.TabIndex = 35;
            this.lblAppName.Text = "Dev";
            this.lblAppName.UseMnemonic = false;
            // 
            // lblListNoGMAs
            // 
            this.lblListNoGMAs.AutoSize = true;
            this.lblListNoGMAs.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblListNoGMAs.ForeColor = System.Drawing.Color.Black;
            this.lblListNoGMAs.Location = new System.Drawing.Point(4, 370);
            this.lblListNoGMAs.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblListNoGMAs.Name = "lblListNoGMAs";
            this.lblListNoGMAs.Size = new System.Drawing.Size(66, 13);
            this.lblListNoGMAs.TabIndex = 36;
            this.lblListNoGMAs.Text = "No GMA for:";
            this.lblListNoGMAs.Visible = false;
            // 
            // tmrFadeLabel
            // 
            this.tmrFadeLabel.Tick += new System.EventHandler(this.tmrFadeLabel_Tick);
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.lblContractName);
            this.groupBox1.Controls.Add(this.txtNewContractName);
            this.groupBox1.Controls.Add(this.btnCopyGMAoffline);
            this.groupBox1.Controls.Add(this.ckbNewBlankContract);
            this.groupBox1.Controls.Add(this.updownJobCnt);
            this.groupBox1.Controls.Add(this.btnGMA);
            this.groupBox1.Controls.Add(this.lblJobsCnt);
            this.groupBox1.Controls.Add(this.txtViewpointContract);
            this.groupBox1.Controls.Add(this.cboJobs);
            this.groupBox1.Controls.Add(this.lblJobs);
            this.groupBox1.Location = new System.Drawing.Point(1, 53);
            this.groupBox1.Margin = new System.Windows.Forms.Padding(2);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Padding = new System.Windows.Forms.Padding(2);
            this.groupBox1.Size = new System.Drawing.Size(97, 315);
            this.groupBox1.TabIndex = 39;
            this.groupBox1.TabStop = false;
            // 
            // lblContractName
            // 
            this.lblContractName.AutoSize = true;
            this.lblContractName.Enabled = false;
            this.lblContractName.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblContractName.Location = new System.Drawing.Point(3, 124);
            this.lblContractName.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblContractName.Name = "lblContractName";
            this.lblContractName.Size = new System.Drawing.Size(92, 15);
            this.lblContractName.TabIndex = 21;
            this.lblContractName.Text = "Contract Name:";
            // 
            // txtNewContractName
            // 
            this.txtNewContractName.Enabled = false;
            this.txtNewContractName.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtNewContractName.Location = new System.Drawing.Point(5, 143);
            this.txtNewContractName.Margin = new System.Windows.Forms.Padding(2);
            this.txtNewContractName.MaxLength = 60;
            this.txtNewContractName.Name = "txtNewContractName";
            this.txtNewContractName.Size = new System.Drawing.Size(89, 21);
            this.txtNewContractName.TabIndex = 4;
            this.txtNewContractName.KeyUp += new System.Windows.Forms.KeyEventHandler(this.txtContractName_KeyUp);
            // 
            // btnCopyGMAoffline
            // 
            this.btnCopyGMAoffline.Enabled = false;
            this.btnCopyGMAoffline.Location = new System.Drawing.Point(4, 268);
            this.btnCopyGMAoffline.Margin = new System.Windows.Forms.Padding(2);
            this.btnCopyGMAoffline.Name = "btnCopyGMAoffline";
            this.btnCopyGMAoffline.Size = new System.Drawing.Size(86, 43);
            this.btnCopyGMAoffline.TabIndex = 7;
            this.btnCopyGMAoffline.Text = "Copy GMA Offline";
            this.btnCopyGMAoffline.UseVisualStyleBackColor = true;
            this.btnCopyGMAoffline.Click += new System.EventHandler(this.btnCopyGMAoffline_Click);
            // 
            // ckbNewBlankContract
            // 
            this.ckbNewBlankContract.Location = new System.Drawing.Point(6, 95);
            this.ckbNewBlankContract.Margin = new System.Windows.Forms.Padding(2);
            this.ckbNewBlankContract.Name = "ckbNewBlankContract";
            this.ckbNewBlankContract.Size = new System.Drawing.Size(87, 26);
            this.ckbNewBlankContract.TabIndex = 3;
            this.ckbNewBlankContract.Text = "New/Blank Contract";
            this.ckbNewBlankContract.UseVisualStyleBackColor = true;
            this.ckbNewBlankContract.CheckedChanged += new System.EventHandler(this.ckbBlankContract_CheckedChanged);
            // 
            // updownJobCnt
            // 
            this.updownJobCnt.Enabled = false;
            this.updownJobCnt.Font = new System.Drawing.Font("Microsoft Sans Serif", 8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.updownJobCnt.Location = new System.Drawing.Point(6, 187);
            this.updownJobCnt.Margin = new System.Windows.Forms.Padding(2);
            this.updownJobCnt.Maximum = new decimal(new int[] {
            20,
            0,
            0,
            0});
            this.updownJobCnt.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.updownJobCnt.Name = "updownJobCnt";
            this.updownJobCnt.Size = new System.Drawing.Size(39, 20);
            this.updownJobCnt.TabIndex = 5;
            this.updownJobCnt.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.updownJobCnt.KeyUp += new System.Windows.Forms.KeyEventHandler(this.updownJobCnt_KeyUp);
            // 
            // lblJobsCnt
            // 
            this.lblJobsCnt.AutoSize = true;
            this.lblJobsCnt.Enabled = false;
            this.lblJobsCnt.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblJobsCnt.Location = new System.Drawing.Point(3, 170);
            this.lblJobsCnt.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblJobsCnt.Name = "lblJobsCnt";
            this.lblJobsCnt.Size = new System.Drawing.Size(64, 15);
            this.lblJobsCnt.TabIndex = 18;
            this.lblJobsCnt.Text = "# Projects:";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(1, 49);
            this.label1.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(111, 15);
            this.label1.TabIndex = 22;
            this.label1.Text = "Viewpoint Contract:";
            // 
            // ActionsPaneGMA
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.AutoSize = true;
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.lblListNoGMAs);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.lblAppName);
            this.Controls.Add(this.picLogo);
            this.errorProvider1.SetIconAlignment(this, System.Windows.Forms.ErrorIconAlignment.MiddleLeft);
            this.Margin = new System.Windows.Forms.Padding(2);
            this.Name = "ActionsPaneGMA";
            this.Size = new System.Drawing.Size(114, 480);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.updownJobCnt)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        public System.Windows.Forms.Button btnGMA;
        private System.Windows.Forms.Label lblJobs;
        public System.Windows.Forms.ComboBox cboJobs;
        public System.Windows.Forms.TextBox txtViewpointContract;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        private System.Windows.Forms.Timer tmrUpdateButtonText;
        private System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
        private System.Windows.Forms.Label lblAppName;
        private System.Windows.Forms.Label lblListNoGMAs;
        private System.Windows.Forms.Timer tmrFadeLabel;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.NumericUpDown updownJobCnt;
        private System.Windows.Forms.Label lblJobsCnt;
        public System.Windows.Forms.Button btnCopyGMAoffline;
        private System.Windows.Forms.CheckBox ckbNewBlankContract;
        private System.Windows.Forms.Label lblContractName;
        public System.Windows.Forms.TextBox txtNewContractName;
        private System.Windows.Forms.Label label1;
    }
}
