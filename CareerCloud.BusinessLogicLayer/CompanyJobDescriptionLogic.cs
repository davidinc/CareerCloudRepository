using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class CompanyJobDescriptionLogic : BaseLogic<CompanyJobDescriptionPoco>
    {
        public CompanyJobDescriptionLogic(IDataRepository<CompanyJobDescriptionPoco> repository) : base(repository) 
        { }

        protected override void Verify(CompanyJobDescriptionPoco[] pocos)
        {

            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();

                // Defining Exceptional validation for ErrorCode 300/301

                if (poco.JobName == "")
                {
                    errors.Add(new ValidationException(300, "JobName cannot be empty"));
                }

                if (poco.JobDescriptions == "")
                {
                    errors.Add(new ValidationException(301, "JobDescriptions cannot be empty"));
                }

                if (poco.JobName == null)
                {
                    errors.Add(new ValidationException(300, "JobName cannot be null"));
                }

                if (poco.JobDescriptions == null)
                {
                    errors.Add(new ValidationException(301, "JobDescriptions cannot be null"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(CompanyJobDescriptionPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(CompanyJobDescriptionPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }

    }
}
