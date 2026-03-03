async function get_ram_size(timeout_ms = 5000)
{
	const url    = "/ram_size";
	const signal = AbortSignal.timeout(timeout_ms);
	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			return -1;
		}
		const result = await response.json();
		if (!result || !result.ram_size) {
			return -1;
		}
		return result.ram_size;

	} catch (error) {
        console.error("Failed to retrieve server's RAM size");
		return -1;
	}
}

function set_error_message(message)
{
	const error_message_div = document.getElementById("error_message");
	if (!error_message_div) {
		console.error("Failed to get error_message_div");
		return -1;
	}
	error_message_div.textContent = message;
	return 0;
}

function setup_event_listeners(ram_size)
{
	const greyed_out_submit_msg = document.getElementById("greyed_out_submit_msg");
	if (!greyed_out_submit_msg) {
		console.error("Failed to get greyed_out_submit_msg");
		return -1;
	}
	const submit_btn = document.getElementById("submit_btn");
	if (!submit_btn) {
		console.error("Failed to get submit_btn");
		return -1;
	}
	const file_selection = document.getElementById("file_selection");
	if (!file_selection) {
		console.error("Failed to get file_selection");
		return -1;
	}

	file_selection.addEventListener('change', function() {
		if (file_selection.files.length > 0) {
			if (ram_size == 0) {
				greyed_out_submit_msg.setAttribute('title', "Waiting on server");
			} else {
				greyed_out_submit_msg.setAttribute('title', "");
				submit_btn.removeAttribute("disabled");
			}
		} else {
			set_error_message("Selected file is empty.");
			return -1;
		}
	});

	const form = document.getElementById("upload_form");
	if (!form) {
		console.error("Failed to get upload_form");
		return -1;
	}

	form.addEventListener('submit', function(event) {
		event.preventDefault();
		set_error_message("");
		const fw_file = file_selection.files[0];
		if (fw_file.size > ram_size) {
			set_error_message(`Error: File size (${
				(fw_file.size / (1024 *1024)).toFixed(2)} MB) exceeds the maximum allowed size of 
                ${ram_size / (1024 * 1024)} MB.`);
		} else {
			form.submit();
			greyed_out_submit_msg.setAttribute('title', "Upload is ongoing");
			submit_btn.setAttribute("disabled", "disabled");
		}
	});
}

async function setup()
{
	var ram_size = await get_ram_size();
	if (ram_size < 0) {
		let reload_count = localStorage.getItem('reload_count') || 0;
		reload_count = Number(reload_count) + 1;
		localStorage.setItem('reload_count', reload_count);
		if ( reload_count < 4) {
			console.warn(`Page has been reloaded ${reload_count} time(s) due to failure receiving ram_size.`);
			location.reload();
			return -1;
		} else {
			console.warn("Using default ram_size of 128 MB");
			ram_size = 134217728;
		}
	}
	localStorage.setItem('reload_count', 0);
	setup_event_listeners(ram_size);
}

async function get_validation_error(timeout_ms = 5000)
{
	const url    = "/validation_status";
	const signal = AbortSignal.timeout(timeout_ms);
	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			return -1;
		}
		const result = await response.json();
		if (!result || !result.flash_error) {
			return -1;
		}
		return result;

	} catch (error) {
        console.error("Failed to get validation_status");
		return -1;
	}
}

async function retrieve_and_show_validation_error()
{
	const validation_error_json = await get_validation_error();
	const err_num		    = validation_error_json.flash_error;
	const err_explanation	    = validation_error_json.error_clarification;

	if (err_num == 1) {
		set_error_message(`Seems like an incorrect firmware image was chosen for this device. Needed \"${err_explanation}\".`);
	} else if (err_num == 2) {
		set_error_message('Seems like an incorrect firmware image was chosen. Bad manifest.');
	} else if (err_num == 3) {
		set_error_message('Seems like an incorrect U-boot image was chosen. Bad checksum.');
	} else if (err_num == 4) {
		set_error_message(`Seems like an incorrect U-boot image was chosen for this device. Needed \"${err_explanation}\".`);
	} else {
		set_error_message('Something went wrong.');
	}
}

function delay(ms)
{
	return new Promise(resolve => setTimeout(resolve, ms));
}

async function get_image_type(timeout_ms = 5000)
{
	const url    = "/image_type";
	const signal = AbortSignal.timeout(timeout_ms);
	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			return -1;
		}
		var data = await response.json();
		if (!data.image_type) {
			return -1;
		}
		return data.image_type;

	} catch (error) {
		console.error("Failed to get image_type");
		return -1;
	}
}

async function get_dev_memory_type(timeout_ms = 5000)
{
	const url    = "/dev_memory_type";
	const signal = AbortSignal.timeout(timeout_ms);
	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			return -1;
		}
		var data = await response.json();
		return data;

	} catch (error) {
		console.error("Failed to get dev_memory_type");
		return -1;
	}
}

async function get_progress(timeout_ms = 5000)
{
	const url    = "/progress_status";
	const signal = AbortSignal.timeout(timeout_ms);
	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			return -1;
		}
		var data = await response.json();
		if (!data) {
			return -1;
		}
		return data;

	} catch (error) {
		if (error.name == 'TimeoutError' || error instanceof TypeError) {
			return -1;
		} else {
			return 1;
		}
	}
}

function update_progress_bars(progress_response_json, progress_table, global_state)
{
	if (global_state.flashing_status == "finished") {
		return;
	}
	var nand_scanning_progress, nand_writing_progress, nand_formatting_progress, nand_reading_progress,
		nand_scan_bar, nand_scan_percentage, nand_writing_bar, nand_writing_percentage,
		nand_format_bar, nand_format_percentage, nand_reading_bar, nand_reading_percentage;

	var mmc_nor_erase_progress, mmc_nor_writing_progress, mmc_nor_erase_bar, mmc_nor_erase_percentage,
		mmc_nor_writing_bar, mmc_nor_writing_percentage;

	if (progress_table.id == "nand_progress_table") {
		nand_scanning_progress	 = progress_response_json.scanning_progress;
		nand_writing_progress	 = progress_response_json.writing_progress;
		nand_formatting_progress = progress_response_json.formatting_progress;
		nand_reading_progress	 = progress_response_json.reading_progress;
		nand_scan_bar			 = document.getElementById("nand_scan_bar");
		nand_scan_percentage	 = document.getElementById("nand_scan_percentage");
		nand_writing_bar		 = document.getElementById("nand_writing_bar");
		nand_writing_percentage	 = document.getElementById("nand_writing_percentage");
		nand_format_bar			 = document.getElementById("nand_format_bar");
		nand_format_percentage	 = document.getElementById("nand_format_percentage");
		nand_reading_bar		 = document.getElementById("nand_reading_bar");
		nand_reading_percentage	 = document.getElementById("nand_reading_percentage");

		try {
			nand_scan_bar.value					 = nand_scanning_progress;
			nand_scan_percentage.innerHTML		 = `Scanning: ${nand_scanning_progress} %`;
			nand_writing_bar.value				 = nand_writing_progress;
			nand_writing_percentage.innerHTML	 = `Writing: ${nand_writing_progress} %`;
			nand_format_bar.value				 = nand_formatting_progress;
			nand_format_percentage.innerHTML	 = `Formatting: ${nand_formatting_progress} %`;
			nand_reading_bar.value				 = nand_reading_progress;
			nand_reading_percentage.innerHTML	 = `Reading: ${nand_reading_progress} %`;

		} catch (error) {
			console.error("Failed to retrieve one of the page elements while executing update_progress_bars().");
		}

	} else {
		mmc_nor_erase_progress		= progress_response_json.erase_progress;
		mmc_nor_writing_progress	= progress_response_json.writing_progress;
		mmc_nor_erase_bar		 	= document.getElementById("mmc_nor_erase_bar");
		mmc_nor_erase_percentage	= document.getElementById("mmc_nor_erase_percentage");
		mmc_nor_writing_bar			= document.getElementById("mmc_nor_writing_bar");
		mmc_nor_writing_percentage	= document.getElementById("mmc_nor_writing_percentage");

		try {
		mmc_nor_erase_bar.value				= mmc_nor_erase_progress;
		mmc_nor_erase_percentage.innerHTML	= `Erasing: ${mmc_nor_erase_progress} %`;
		mmc_nor_writing_bar.value				= mmc_nor_writing_progress;
		mmc_nor_writing_percentage.innerHTML	= `Writing: ${mmc_nor_writing_progress} %`;

		} catch (error) {
			console.error("Failed to retrieve one of the page elements while executing update_progress_bars().");
		}
	}
}

function show_flash_failure(main, details)
{
			main.innerHTML =
				`<h1 class=\"heading\" style=\"color:red; text-align: center;\">FLASHING FAILED</h1>`;
			details.innerHTML	= "Something went wrong during flashing. Please, try again.<br><br>";
			details.style.textAlign = "center";
}

async function set_flashing_result(progress_response_json, timer, progress_table, global_state)
{
	const result = progress_response_json.result;
	try {
		const main	     = document.getElementById("main");
		const details	     = document.getElementById("details");
		if (result == "success") {
			global_state.flashing_status = "finished";
			progress_table.remove();
			main.innerHTML =
				`<h1 class="heading" style="color:#1941a5; text-align:center;">SUCCESS!<br>REBOOTING IN PROGRESS</h1>`;
			details.innerHTML =
               `Page now can be closed.<br> <br>
				 Once rebooting finishes You can open the Web interface.<br> <br> `;
			details.style.textAlign = "center";
			return 0;

		} else if (result == "failed") {
			global_state.flashing_status = "finished";
			progress_table.remove();
			show_flash_failure(main, details);
			return 0;
		}
		timer = setInterval(() => { progress(timer, global_state, progress_table); }, 1000);
		return 1;
	} catch (error) {
		console.error("Failed to retrieve one of the page elements while executing set_flashing_result().");
		return -1;
	}
}

function show_lost_connection(global_state, progress_table)
{
	try {
		const main	     = document.getElementById("main");
		const details	 = document.getElementById("details");
		progress_table.remove();
		main.innerHTML	  = `<h1 class=\"heading\" style=\"color:red; text-align: center;\">CONNECTION LOST</h1>`;
		details.innerHTML = "Ensure proper ethernet connection, restart the device and redo the update<br>. ";
		details.style.textAlign = "center";
		global_state.connection_state = "disconnected";
	} catch (error) {
		console.error("Failed to retrieve one of the page elements while executing show_lost_connection().");
		return -1;
	}
}

async function progress(timer, global_state, progress_table)
{
	clearInterval(timer);
	var progress_json = await get_progress();
	if (progress_json == -1) {
		global_state.progress_request_retry_count++;
		if (global_state.progress_request_retry_count < 3) {
			timer = setInterval(() => { progress(timer, global_state, progress_table); }, 1000);
			return;
		}
		if (global_state.connection_state == "connected") {
			show_lost_connection(global_state, progress_table);
		}
		return;
	}
	global_state.progress_request_retry_count = 0;
	update_progress_bars(progress_json, progress_table, global_state);
	set_flashing_result(progress_json, timer, progress_table, global_state);

	return;
}

async function start_flashing_process()
{	
	let global_state = { connection_state: "connected" , flashing_status: "unfinished" , progress_request_retry_count: 0 };
	let progress_timer_id;
	const main	     = document.getElementById("main");
	const details	     = document.getElementById("details");

	var image_type = await get_image_type();
	if (image_type == -1){
		show_flash_failure(main, details);
		return;
	}

	var dev_memory_type_json = await get_dev_memory_type();
	if (dev_memory_type_json === -1) {
		show_flash_failure(main, details);
		return;
	}
	var dev_memory_type = dev_memory_type_json.dev_memory_type;
	if (dev_memory_type != "NOR" && dev_memory_type != "NAND" && dev_memory_type != "MMC") {
		show_flash_failure(main, details);
		return;
	}

	if (image_type == "firmware") {
		details.innerHTML =
			"Your file was successfully uploaded! Upgrading is in progress.<br> After progress bars fill up wait a little to see the flashing process result";
		var progress_table;
		if (dev_memory_type == "NAND") {
			progress_table = document.getElementById("nand_progress_table");
		} else {
			progress_table = document.getElementById("mmc_nor_progress_table");
		}
		progress_table.style.display = "table";
		progress_timer_id = setInterval(() => { progress(progress_timer_id, global_state, progress_table); }, 1000);
	}

	const url    = "/update_image";
	var signal;
	signal = AbortSignal.timeout(50000);

	try {
		const response = await fetch(url, { signal });
		if (!response.ok) {
			show_flash_failure(main, details);
			return;
		}
		var text_data = await response.text();
		if (text_data.length === 0) {
			return;
		}
		data = JSON.parse(text_data);
		if (!data) {
			show_flash_failure(main, details);
			return;
		}
		var outcome = data.outcome;
		if (outcome == "succeeded") {
			main.innerHTML =
				`<h1 class=\"heading\" style=\"color:#1941a5; text-align:center;\">SUCCESS!<br>REBOOTING IN PROGRESS</h1>`;
			details.innerHTML =
				`Page now can be closed.<br> <br>
				 Once rebooting finishes You can open the Web interface.<br> <br> `;
			details.style.textAlign = "center";
		} else if (outcome == "failed") {
			main.innerHTML =
				"<h1 class=\"heading\" style=\"color:red; text-align:center;\">FLASHING FAILED</h1>";
			details.innerHTML	= "Something went wrong during flashing. Please, try again.";
			details.style.textAlign = "center";
		}
	} catch (error) {
		if (error.name == "AbortError" || error.name == "TypeError") {
			console.log(`Caught an error: ${error.name}`);
			return;
		}
		console.error(`Caught an error: ${error.name}`);
		if (error.name == "AbortError") {
			show_lost_connection(global_state, progress_table);
		} else {
			show_flash_failure(main, details);
		}
	}
}