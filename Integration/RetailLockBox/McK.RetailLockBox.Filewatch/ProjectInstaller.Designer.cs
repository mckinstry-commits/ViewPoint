namespace McK.RetailLockBox.Folderwatch
{
    partial class ProjectInstaller
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
            this.McKServiceProcessInstaller_RLB = new System.ServiceProcess.ServiceProcessInstaller();
            this.McKServiceInstaller_RLB = new System.ServiceProcess.ServiceInstaller();
            // 
            // McKServiceProcessInstaller_RLB
            // 
            this.McKServiceProcessInstaller_RLB.Account = System.ServiceProcess.ServiceAccount.LocalSystem;
            this.McKServiceProcessInstaller_RLB.Password = null;
            this.McKServiceProcessInstaller_RLB.Username = null;
            // 
            // McKServiceInstaller_RLB
            // 
            this.McKServiceInstaller_RLB.ServiceName = "McK RLB Download To Drop Folder Watcher";
            this.McKServiceInstaller_RLB.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            // 
            // ProjectInstaller
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            this.McKServiceInstaller_RLB,
            this.McKServiceProcessInstaller_RLB});

        }

        #endregion

        private System.ServiceProcess.ServiceProcessInstaller McKServiceProcessInstaller_RLB;
        private System.ServiceProcess.ServiceInstaller McKServiceInstaller_RLB;
    }
}