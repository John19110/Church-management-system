using Church.API.Services.Interfaces;
using Church.BLL.Authorization;
using Church.BLL.DTOS.OptionalModules;
using Church.BLL.Manager.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net.Mime;

namespace Church.API.Controllers
{
    [Route("api/stock-items")]
    [ApiController]
    [Authorize(Policy = OptionalModulePolicies.UseStock)]
    public class StockItemController : ControllerBase
    {
        private readonly IStockItemManager _manager;
        private readonly IFileStorage _fileStorage;

        public StockItemController(IStockItemManager manager, IFileStorage fileStorage)
        {
            _manager = manager;
            _fileStorage = fileStorage;
        }

        [HttpGet]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<StockItemReadDto>>> GetAll(
            [FromQuery] string? search = null)
        {
            return Ok(await _manager.GetAllAsync(search));
        }

        [HttpGet("{id:int}")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockItemReadDto>> GetById(int id)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            var item = await _manager.GetByIdAsync(id);
            return item == null ? NotFound() : Ok(item);
        }

        [HttpPost]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockItemReadDto>> Create([FromBody] StockItemCreateDto dto)
        {
            var created = await _manager.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id:int}")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockItemReadDto>> Update(int id, [FromBody] StockItemUpdateDto dto)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            return Ok(await _manager.UpdateAsync(id, dto));
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            await _manager.DeleteAsync(id);
            return NoContent();
        }

        [HttpPost("{id:int}/increase")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockAmountChangeResultDto>> Increase(int id)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            return Ok(await _manager.IncreaseAmountAsync(id));
        }

        [HttpPost("{id:int}/decrease")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockAmountChangeResultDto>> Decrease(int id)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            return Ok(await _manager.DecreaseAmountAsync(id));
        }

        [HttpPost("{id:int}/image")]
        [Consumes("multipart/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<StockItemReadDto>> UploadImage(
            int id,
            IFormFile image,
            CancellationToken ct)
        {
            if (id <= 0) return BadRequest("Stock item id must be a positive integer.");
            if (image == null || image.Length == 0)
                return BadRequest("Image file is required.");

            var key = await _fileStorage.SaveImageAsync(image, ct, "stock");
            await _manager.UpdateImageAsync(id, key, _fileStorage.GetPublicUrl(key));
            var item = await _manager.GetByIdAsync(id);
            return item == null ? NotFound() : Ok(item);
        }
    }
}
