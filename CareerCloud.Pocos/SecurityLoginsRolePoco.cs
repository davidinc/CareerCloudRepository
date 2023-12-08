using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CareerCloud.Pocos
{
    [Table("Security_Logins_Roles")]
    public class SecurityLoginsRolePoco:IPoco
    {
        [Column("Id")]
        [Key]
        public Guid Id { get; set; }
        [Column("Login")]
        public Guid Login { get; set; }
        [Column("Role")]
        public Guid Role { get; set; }
        [Column("Time_Stamp")]
        [NotMapped]
        public byte[]? TimeStamp { get; set; }

        //Virtual link with affiliate table
        public virtual SecurityLoginPoco? SecurityLogin { get; set; }
        public virtual SecurityRolePoco? SecurityRole { get; set; }

    }
}
