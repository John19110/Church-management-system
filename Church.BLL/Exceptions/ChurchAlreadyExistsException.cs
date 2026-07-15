namespace Church.BLL.Exceptions
{
    public class ChurchAlreadyExistsException : Exception
    {
        public ChurchAlreadyExistsException(string message = "Church already exists.")
            : base(message)
        {
        }
    }
}
