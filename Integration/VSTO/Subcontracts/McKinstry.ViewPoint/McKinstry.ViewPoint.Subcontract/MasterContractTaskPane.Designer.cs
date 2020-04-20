namespace McKinstry.ViewPoint.Subcontract
{
    partial class MasterContractTaskPane
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

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.tbVendorNumber = new System.Windows.Forms.TextBox();
            this.lblVendorNumber = new System.Windows.Forms.Label();
            this.bGenerateMaster = new System.Windows.Forms.Button();
            this.cbCompany = new System.Windows.Forms.ComboBox();
            this.label1 = new System.Windows.Forms.Label();
            this.lbSequence = new System.Windows.Forms.Label();
            this.tbSequence = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.cbCompanyName = new System.Windows.Forms.ComboBox();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // pictureBox1
            // 
            this.pictureBox1.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.McKLogo;
            this.pictureBox1.Location = new System.Drawing.Point(0, 0);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(289, 101);
            this.pictureBox1.TabIndex = 0;
            this.pictureBox1.TabStop = false;
            // 
            // tbVendorNumber
            // 
            this.tbVendorNumber.Location = new System.Drawing.Point(99, 127);
            this.tbVendorNumber.Name = "tbVendorNumber";
            this.tbVendorNumber.Size = new System.Drawing.Size(197, 20);
            this.tbVendorNumber.TabIndex = 1;
            // 
            // lblVendorNumber
            // 
            this.lblVendorNumber.AutoSize = true;
            this.lblVendorNumber.Location = new System.Drawing.Point(3, 130);
            this.lblVendorNumber.Name = "lblVendorNumber";
            this.lblVendorNumber.Size = new System.Drawing.Size(87, 13);
            this.lblVendorNumber.TabIndex = 2;
            this.lblVendorNumber.Text = "Vendor Number :";
            // 
            // bGenerateMaster
            // 
            this.bGenerateMaster.BackColor = System.Drawing.Color.SlateGray;
            this.bGenerateMaster.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.bGenerateMaster.ForeColor = System.Drawing.Color.Blue;
            this.bGenerateMaster.Location = new System.Drawing.Point(6, 329);
            this.bGenerateMaster.Name = "bGenerateMaster";
            this.bGenerateMaster.Size = new System.Drawing.Size(290, 53);
            this.bGenerateMaster.TabIndex = 6;
            this.bGenerateMaster.Text = "Generate Master Contract";
            this.bGenerateMaster.UseVisualStyleBackColor = false;
            this.bGenerateMaster.Click += new System.EventHandler(this.bGenerateMaster_Click);
            // 
            // cbCompany
            // 
            this.cbCompany.DisplayMember = "Text";
            this.cbCompany.FormattingEnabled = true;
            this.cbCompany.Location = new System.Drawing.Point(99, 203);
            this.cbCompany.Name = "cbCompany";
            this.cbCompany.Size = new System.Drawing.Size(197, 21);
            this.cbCompany.TabIndex = 7;
            this.cbCompany.ValueMember = "Value";
            this.cbCompany.SelectedIndexChanged += new System.EventHandler(this.cbCompany_SelectedIndexChanged);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(3, 211);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(79, 13);
            this.label1.TabIndex = 8;
            this.label1.Text = "Vendor Group :";
            // 
            // lbSequence
            // 
            this.lbSequence.AutoSize = true;
            this.lbSequence.Location = new System.Drawing.Point(3, 167);
            this.lbSequence.Name = "lbSequence";
            this.lbSequence.Size = new System.Drawing.Size(62, 13);
            this.lbSequence.TabIndex = 10;
            this.lbSequence.Text = "Sequence :";
            // 
            // tbSequence
            // 
            this.tbSequence.Location = new System.Drawing.Point(99, 164);
            this.tbSequence.Name = "tbSequence";
            this.tbSequence.Size = new System.Drawing.Size(197, 20);
            this.tbSequence.TabIndex = 9;
            this.tbSequence.Text = "1";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.label2.ForeColor = System.Drawing.SystemColors.ControlText;
            this.label2.Location = new System.Drawing.Point(3, 262);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(57, 13);
            this.label2.TabIndex = 12;
            this.label2.Text = "Company :";
            // 
            // cbCompanyName
            // 
            this.cbCompanyName.DisplayMember = "Text";
            this.cbCompanyName.FormattingEnabled = true;
            this.cbCompanyName.Location = new System.Drawing.Point(98, 254);
            this.cbCompanyName.Name = "cbCompanyName";
            this.cbCompanyName.Size = new System.Drawing.Size(198, 21);
            this.cbCompanyName.TabIndex = 11;
            this.cbCompanyName.ValueMember = "Value";
            // 
            // MasterContractTaskPane
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.AliceBlue;
            this.Controls.Add(this.label2);
            this.Controls.Add(this.cbCompanyName);
            this.Controls.Add(this.lbSequence);
            this.Controls.Add(this.tbSequence);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.cbCompany);
            this.Controls.Add(this.bGenerateMaster);
            this.Controls.Add(this.lblVendorNumber);
            this.Controls.Add(this.tbVendorNumber);
            this.Controls.Add(this.pictureBox1);
            this.Name = "MasterContractTaskPane";
            this.Size = new System.Drawing.Size(311, 424);
            this.Load += new System.EventHandler(this.MasterContractTaskPane_Load);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.TextBox tbVendorNumber;
        private System.Windows.Forms.Label lblVendorNumber;
        private System.Windows.Forms.Button bGenerateMaster;
        private System.Windows.Forms.ComboBox cbCompany;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label lbSequence;
        private System.Windows.Forms.TextBox tbSequence;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cbCompanyName;
    }
}
