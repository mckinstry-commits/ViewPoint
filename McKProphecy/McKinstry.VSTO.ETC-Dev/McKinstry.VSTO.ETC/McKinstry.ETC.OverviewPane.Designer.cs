namespace McKinstry.ETC.Template
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ETCOverviewActionPane
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
            this.lblContract = new System.Windows.Forms.Label();
            this.txtBoxContract = new System.Windows.Forms.TextBox();
            this.btnFetchData = new System.Windows.Forms.Button();
            this.lblMonth = new System.Windows.Forms.Label();
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.cboMonth = new System.Windows.Forms.ComboBox();
            this.lblProject = new System.Windows.Forms.Label();
            this.btnCancelRevBatch = new System.Windows.Forms.Button();
            this.btnCancelCostBatch = new System.Windows.Forms.Button();
            this.cboJobs = new System.Windows.Forms.ComboBox();
            this.btnPostRev = new System.Windows.Forms.Button();
            this.btnPostCost = new System.Windows.Forms.Button();
            this.groupPost = new System.Windows.Forms.GroupBox();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            this.btnGMAX = new System.Windows.Forms.Button();
            this.btnCopyDetailOffline = new System.Windows.Forms.Button();
            this.tmrSavedChangeCaption = new System.Windows.Forms.Timer(this.components);
            this.btnProjectedRevCurve = new System.Windows.Forms.Button();
            this.tmrWaitSortWinClose = new System.Windows.Forms.Timer(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            this.groupPost.SuspendLayout();
            this.SuspendLayout();
            // 
            // lblContract
            // 
            this.lblContract.AutoSize = true;
            this.lblContract.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblContract.Location = new System.Drawing.Point(5, 63);
            this.lblContract.Name = "lblContract";
            this.lblContract.Size = new System.Drawing.Size(60, 16);
            this.lblContract.TabIndex = 0;
            this.lblContract.Text = "Contract:";
            // 
            // txtBoxContract
            // 
            this.txtBoxContract.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtBoxContract.Location = new System.Drawing.Point(7, 85);
            this.txtBoxContract.Name = "txtBoxContract";
            this.txtBoxContract.Size = new System.Drawing.Size(96, 21);
            this.txtBoxContract.TabIndex = 0;
            this.txtBoxContract.MouseClick += new System.Windows.Forms.MouseEventHandler(this.txtContractNumber_MouseClick);
            this.txtBoxContract.Enter += new System.EventHandler(this.txtContractNumber_Enter);
            this.txtBoxContract.KeyUp += new System.Windows.Forms.KeyEventHandler(this.txtBoxContract_KeyUp);
            // 
            // btnFetchData
            // 
            this.btnFetchData.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.btnFetchData.Location = new System.Drawing.Point(9, 253);
            this.btnFetchData.Name = "btnFetchData";
            this.btnFetchData.Size = new System.Drawing.Size(94, 52);
            this.btnFetchData.TabIndex = 3;
            this.btnFetchData.Text = "Get Contract && Projects";
            this.btnFetchData.UseVisualStyleBackColor = true;
            this.btnFetchData.Click += new System.EventHandler(this.btnFetchData_Click);
            // 
            // lblMonth
            // 
            this.lblMonth.AutoSize = true;
            this.lblMonth.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblMonth.Location = new System.Drawing.Point(8, 187);
            this.lblMonth.Name = "lblMonth";
            this.lblMonth.Size = new System.Drawing.Size(47, 16);
            this.lblMonth.TabIndex = 4;
            this.lblMonth.Text = "Month:";
            this.lblMonth.Visible = false;
            // 
            // picLogo
            // 
            this.picLogo.Image = global::McKinstry.ETC.Template.Properties.Resources.McKinstryLogo;
            this.picLogo.Location = new System.Drawing.Point(10, 4);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(91, 48);
            this.picLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picLogo.TabIndex = 3;
            this.picLogo.TabStop = false;
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // cboMonth
            // 
            this.cboMonth.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cboMonth.FormattingEnabled = true;
            this.cboMonth.Location = new System.Drawing.Point(9, 212);
            this.cboMonth.Name = "cboMonth";
            this.cboMonth.Size = new System.Drawing.Size(96, 23);
            this.cboMonth.TabIndex = 2;
            this.cboMonth.SelectedIndexChanged += new System.EventHandler(this.dpMonth_IndexChanged);
            // 
            // lblProject
            // 
            this.lblProject.AutoSize = true;
            this.lblProject.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblProject.Location = new System.Drawing.Point(6, 122);
            this.lblProject.Name = "lblProject";
            this.lblProject.Size = new System.Drawing.Size(53, 16);
            this.lblProject.TabIndex = 8;
            this.lblProject.Text = "Project:";
            // 
            // btnCancelRevBatch
            // 
            this.btnCancelRevBatch.Enabled = false;
            this.btnCancelRevBatch.Location = new System.Drawing.Point(4, 14);
            this.btnCancelRevBatch.Name = "btnCancelRevBatch";
            this.btnCancelRevBatch.Size = new System.Drawing.Size(94, 51);
            this.btnCancelRevBatch.TabIndex = 9;
            this.btnCancelRevBatch.Text = "&Cancel Rev Batch:";
            this.btnCancelRevBatch.UseVisualStyleBackColor = true;
            this.btnCancelRevBatch.Click += new System.EventHandler(this.btnCancelRevBatch_Click);
            // 
            // btnCancelCostBatch
            // 
            this.btnCancelCostBatch.Enabled = false;
            this.btnCancelCostBatch.Location = new System.Drawing.Point(4, 76);
            this.btnCancelCostBatch.Name = "btnCancelCostBatch";
            this.btnCancelCostBatch.Size = new System.Drawing.Size(94, 51);
            this.btnCancelCostBatch.TabIndex = 10;
            this.btnCancelCostBatch.Text = "&Cancel Cost Batch:";
            this.btnCancelCostBatch.UseVisualStyleBackColor = true;
            this.btnCancelCostBatch.Click += new System.EventHandler(this.btnCancelCostBatch_Click);
            // 
            // cboJobs
            // 
            this.cboJobs.DropDownHeight = 109;
            this.cboJobs.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboJobs.FormattingEnabled = true;
            this.cboJobs.IntegralHeight = false;
            this.cboJobs.ItemHeight = 15;
            this.cboJobs.Location = new System.Drawing.Point(7, 148);
            this.cboJobs.Name = "cboJobs";
            this.cboJobs.Size = new System.Drawing.Size(99, 23);
            this.cboJobs.TabIndex = 2;
            this.cboJobs.Enter += new System.EventHandler(this.cboJobs_Enter);
            this.cboJobs.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboJobs_KeyUp);
            // 
            // btnPostRev
            // 
            this.btnPostRev.Enabled = false;
            this.btnPostRev.Location = new System.Drawing.Point(7, 449);
            this.btnPostRev.Name = "btnPostRev";
            this.btnPostRev.Size = new System.Drawing.Size(94, 51);
            this.btnPostRev.TabIndex = 11;
            this.btnPostRev.Text = "&Post Rev Batch";
            this.btnPostRev.UseVisualStyleBackColor = true;
            this.btnPostRev.Visible = false;
            this.btnPostRev.Click += new System.EventHandler(this.btnPostRev_Click);
            // 
            // btnPostCost
            // 
            this.btnPostCost.Enabled = false;
            this.btnPostCost.Location = new System.Drawing.Point(7, 501);
            this.btnPostCost.Name = "btnPostCost";
            this.btnPostCost.Size = new System.Drawing.Size(93, 51);
            this.btnPostCost.TabIndex = 12;
            this.btnPostCost.Text = "&Post Cost Batch";
            this.btnPostCost.UseVisualStyleBackColor = true;
            this.btnPostCost.Visible = false;
            this.btnPostCost.Click += new System.EventHandler(this.btnPostCost_Click);
            // 
            // groupPost
            // 
            this.groupPost.Controls.Add(this.btnCancelCostBatch);
            this.groupPost.Controls.Add(this.btnCancelRevBatch);
            this.groupPost.Location = new System.Drawing.Point(4, 311);
            this.groupPost.Name = "groupPost";
            this.groupPost.Size = new System.Drawing.Size(102, 133);
            this.groupPost.TabIndex = 13;
            this.groupPost.TabStop = false;
            // 
            // btnGMAX
            // 
            this.btnGMAX.Location = new System.Drawing.Point(115, 357);
            this.btnGMAX.Name = "btnGMAX";
            this.btnGMAX.Size = new System.Drawing.Size(93, 51);
            this.btnGMAX.TabIndex = 14;
            this.btnGMAX.Text = "&GMAX Worksheet";
            this.btnGMAX.UseVisualStyleBackColor = true;
            this.btnGMAX.Visible = false;
            this.btnGMAX.Click += new System.EventHandler(this.btnGMAX_Click);
            // 
            // btnCopyDetailOffline
            // 
            this.btnCopyDetailOffline.Location = new System.Drawing.Point(115, 411);
            this.btnCopyDetailOffline.Name = "btnCopyDetailOffline";
            this.btnCopyDetailOffline.Size = new System.Drawing.Size(93, 51);
            this.btnCopyDetailOffline.TabIndex = 15;
            this.btnCopyDetailOffline.Text = "Copy Cost Detail Offline";
            this.btnCopyDetailOffline.UseVisualStyleBackColor = true;
            this.btnCopyDetailOffline.Visible = false;
            this.btnCopyDetailOffline.Click += new System.EventHandler(this.btnCopy_CostDetail_GMAX_FutureCurve_Offline_Click);
            // 
            // tmrSavedChangeCaption
            // 
            this.tmrSavedChangeCaption.Interval = 1307;
            this.tmrSavedChangeCaption.Tick += new System.EventHandler(this.tmrSavedChangeCaption_Tick);
            // 
            // btnProjectedRevCurve
            // 
            this.btnProjectedRevCurve.Location = new System.Drawing.Point(115, 468);
            this.btnProjectedRevCurve.Name = "btnProjectedRevCurve";
            this.btnProjectedRevCurve.Size = new System.Drawing.Size(93, 51);
            this.btnProjectedRevCurve.TabIndex = 16;
            this.btnProjectedRevCurve.Text = "Projected Revenue Curve";
            this.btnProjectedRevCurve.UseVisualStyleBackColor = true;
            this.btnProjectedRevCurve.Visible = false;
            this.btnProjectedRevCurve.Click += new System.EventHandler(this.btnFutureCurve_Click);
            // 
            // tmrWaitSortWinClose
            // 
            this.tmrWaitSortWinClose.Interval = 750;
            this.tmrWaitSortWinClose.Tick += new System.EventHandler(this.tmrWaitSortWinClose_Tick);
            // 
            // ETCOverviewActionPane
            // 
            this.Controls.Add(this.btnProjectedRevCurve);
            this.Controls.Add(this.btnCopyDetailOffline);
            this.Controls.Add(this.btnGMAX);
            this.Controls.Add(this.btnPostCost);
            this.Controls.Add(this.btnPostRev);
            this.Controls.Add(this.groupPost);
            this.Controls.Add(this.lblProject);
            this.Controls.Add(this.cboJobs);
            this.Controls.Add(this.cboMonth);
            this.Controls.Add(this.lblMonth);
            this.Controls.Add(this.picLogo);
            this.Controls.Add(this.btnFetchData);
            this.Controls.Add(this.txtBoxContract);
            this.Controls.Add(this.lblContract);
            this.DoubleBuffered = true;
            this.Name = "ETCOverviewActionPane";
            this.Size = new System.Drawing.Size(251, 730);
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            this.groupPost.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox picLogo;
        private System.Windows.Forms.Label lblContract;
        private System.Windows.Forms.Label lblProject;

        // for Control sheet access
        public System.Windows.Forms.Label lblMonth;
        public System.Windows.Forms.ComboBox cboMonth;
        public System.Windows.Forms.TextBox txtBoxContract;
        public System.Windows.Forms.Button btnFetchData;
        public System.Windows.Forms.ErrorProvider errorProvider1;
        public System.Windows.Forms.Button btnCancelRevBatch;
        public System.Windows.Forms.Button btnCancelCostBatch;
        public System.Windows.Forms.ComboBox cboJobs;
        public System.Windows.Forms.Button btnPostCost;
        public System.Windows.Forms.Button btnPostRev;
        public System.Windows.Forms.GroupBox groupPost;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
        public System.Windows.Forms.Button btnGMAX;
        public System.Windows.Forms.Button btnCopyDetailOffline;
        private System.Windows.Forms.Timer tmrSavedChangeCaption;
        public System.Windows.Forms.Button btnProjectedRevCurve;
        public System.Windows.Forms.Timer tmrWaitSortWinClose;
    }
}
