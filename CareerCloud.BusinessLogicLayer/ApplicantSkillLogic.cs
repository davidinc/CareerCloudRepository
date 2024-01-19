using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class ApplicantSkillLogic : BaseLogic<ApplicantSkillPoco>
        
    {
        public ApplicantSkillLogic(IDataRepository<ApplicantSkillPoco> repository) : base(repository) 
        { }

        protected override void Verify(ApplicantSkillPoco[] pocos)
        {

            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();

                // Defining Exceptional validation for ErrorCode 101/102/103/104

                if (poco.StartMonth > 12)
                {
                    errors.Add(new ValidationException(101, "Cannot be greater than 12"));
                }

                if (poco.EndMonth > 12)
                {
                    errors.Add(new ValidationException(102, "Cannot be greater than 12"));
                }

                if (poco.StartYear < 1900)
                {
                    errors.Add(new ValidationException(103, "Cannot be less then 1900"));
                }

                if (poco.EndYear < poco.StartYear)
                {
                    errors.Add(new ValidationException(104, "Cannot be less then StartYear"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(ApplicantSkillPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(ApplicantSkillPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }

    }
}
