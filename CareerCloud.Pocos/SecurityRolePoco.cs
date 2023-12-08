using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CareerCloud.Pocos
{
    [Table("Security_Roles")]
    public class SecurityRolePoco:IPoco
    {
        [Column("Id")]
        [Key]
        public Guid Id { get; set; }
        [Column("Role")]
        public string? Role { get; set; }
        [Column("Is_Inactive")]
       
        public bool IsInactive { get; set; }
        //Virtual link with affiliate table
        public virtual ICollection<SecurityLoginsRolePoco>? SecurityLoginsRoles { get; set; }
    }
}
