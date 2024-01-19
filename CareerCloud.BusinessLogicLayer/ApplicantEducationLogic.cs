using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class ApplicantEducationLogic : BaseLogic<ApplicantEducationPoco>
    {

        public ApplicantEducationLogic(IDataRepository<ApplicantEducationPoco> repository) : base(repository)
        { }

        protected override void Verify(ApplicantEducationPoco[] pocos)
        {

            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();
                // Defining Exceptional validation for ErrorCode 107/108/109

                if (poco.Major == null || poco.Major.Length < 3)
                {
                    errors.Add(new ValidationException ( 107, "Cannot be empty or less than 3 characters" ));
                }
                
                if (poco.StartDate > DateTime.Today)
                {
                    errors.Add(new ValidationException(108, "Cannot be greater than today"));
                }

                if (poco.CompletionDate < poco.StartDate)
                {
                    errors.Add(new ValidationException(109, "CompletionDate cannot be earlier than StartDate"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }
            
        }

        public override void Add(ApplicantEducationPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(ApplicantEducationPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }



    }
}
