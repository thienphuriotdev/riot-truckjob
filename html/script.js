let trucks = [];
let trailers = [];
let imageCache = {}; 

let requestAnimId;
let particlesCreated = false;

// const IMAGE_BASE_PATH = "img/vehicles/";
const IMAGE_BASE_PATH = "nui://riot-truckjob/html/img/vehicles/"; 

const preloadImages = [];

$(document).ready(function() {
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'open') {
            $('#truck-job-container').css('display', 'flex');
            
            if (data.jobMenu) {
                $('#main-menu').addClass('active');
            } else if (data.returnMenu) {
                $('#return-menu').addClass('active');
            }
            
            if (!particlesCreated) {
                initializeParticles();
                particlesCreated = true;
            }
        } else if (data.action === 'setupData') {
            console.log('Received setupData:', data);
            trucks = data.trucks || [];
            trailers = data.trailers || [];
            
            // console.log('Trucks count:', trucks.length);
            // console.log('Trailers count:', trailers.length);
            
            collectImagesToPreload();
            
            preloadAllImages().then(() => {
                // console.log('All images preloaded, setting up UI');
                setupVehicleSelections();
            }).catch(err => {
                // console.error('Error preloading images:', err);
                setupVehicleSelections(); 
            });
        }
    });
    
    // Close buttons
    $('.close-btn').click(function() {
        closeAllMenus();
        $.post('https://riot-truckjob/closeMenu', JSON.stringify({}));
    });
    
    // Back buttons
    $('#back-to-main-from-truck').click(function() {
        $('#truck-selection').removeClass('active');
        $('#main-menu').addClass('active');
    });
    
    $('#back-to-main-from-container').click(function() {
        $('#container-selection').removeClass('active');
        $('#main-menu').addClass('active');
    });
    
    // Main menu
    $('#truck-job').click(function() {
        $('#main-menu').removeClass('active');
        $('#truck-selection').addClass('active');
    });
    
    $('#container-job').click(function() {
        $('#main-menu').removeClass('active');
        $('#container-selection').addClass('active');
    });
    
    // Return menu
    $('#complete-job').click(function() {
        closeAllMenus();
        $.post('https://riot-truckjob/completeJob', JSON.stringify({}));
    });
    
    $('#cancel-job').click(function() {
        closeAllMenus();
        $.post('https://riot-truckjob/cancelJob', JSON.stringify({}));
    });
    

    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeAllMenus();
            $.post('https://riot-truckjob/closeMenu', JSON.stringify({}));
        }
    });
});


function collectImagesToPreload() {
    preloadImages.length = 0;
    
    if (trucks && trucks.length > 0) {
        trucks.forEach(truck => {
            preloadImages.push(`${IMAGE_BASE_PATH}${truck.model}.png`);
        });
    }
    

    if (trailers && trailers.length > 0) {
        trailers.forEach(trailer => {
            preloadImages.push(`${IMAGE_BASE_PATH}${trailer.model}.png`);
        });
    }
    
    console.log('Images to preload:', preloadImages);
}


function preloadAllImages() {
    return new Promise((resolve) => {
        if (preloadImages.length === 0) {
            // console.log('No images to preload');
            resolve();
            return;
        }
        
        const preloadPromises = preloadImages.map(imageSrc => imageExists(imageSrc));
        
        Promise.all(preloadPromises).then(results => {
            // console.log('All images checked, results:', results);
            resolve();
        }).catch(err => {
            // console.error('Error in preloading images:', err);
            resolve(); 
        });
    });
}

function initializeParticles() {
    const particlesContainer = document.getElementById('particles');
    const maxParticles = 50; 
    
    particlesContainer.innerHTML = '';
    
    for (let i = 0; i < maxParticles; i++) {
        const particle = document.createElement('div');
        particle.classList.add('particle');
        
        const x = Math.random() * 100;
        const y = Math.random() * 100;
        
        const moveX = (Math.random() - 0.5) * 100;
        const moveY = (Math.random() - 0.5) * 100;
        
        const delay = Math.random() * 20;
        
        particle.style.left = `${x}vw`;
        particle.style.top = `${y}vh`;
        particle.style.opacity = '0';
        particle.style.setProperty('--move-x', `${moveX}vw`);
        particle.style.setProperty('--move-y', `${moveY}vh`);
        particle.style.animationDelay = `${delay}s`;
        
        particlesContainer.appendChild(particle);
    }
}

function imageExists(imageSrc) {
    return new Promise((resolve) => {
        console.log(`Checking image: ${imageSrc}`);
        
        if (imageCache[imageSrc] !== undefined) {
            console.log(`Image ${imageSrc} from cache: ${imageCache[imageSrc]}`);
            resolve(imageCache[imageSrc]);
            return;
        }
        
        const img = new Image();
        
        const timeoutId = setTimeout(() => {
            if (imageCache[imageSrc] === undefined) {
                console.log(`Image ${imageSrc} loading timed out`);
                imageCache[imageSrc] = false;
                resolve(false);
            }
        }, 3000);
        
        img.onload = function() {
            clearTimeout(timeoutId);
            imageCache[imageSrc] = true;
            console.log(`Image ${imageSrc} loaded successfully`);
            resolve(true);
        };
        
        img.onerror = function() {
            clearTimeout(timeoutId);
            imageCache[imageSrc] = false;
            console.log(`Image ${imageSrc} failed to load`);
            resolve(false);
        };
        
        img.src = imageSrc;
        
        if (navigator.userAgent.indexOf('Chrome') !== -1) {
            const xhr = new XMLHttpRequest();
            xhr.open('HEAD', imageSrc, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    if (xhr.status === 200) {
                        clearTimeout(timeoutId);
                        imageCache[imageSrc] = true;
                        console.log(`Image ${imageSrc} verified via XHR`);
                        resolve(true);
                    } else if (xhr.status === 404) {
                        if (imageCache[imageSrc] === undefined) {
                            imageCache[imageSrc] = false;
                            console.log(`Image ${imageSrc} not found via XHR (404)`);
                            resolve(false);
                        }
                    }
                }
            };
            xhr.send();
        }
    });
}

async function setupVehicleSelections() {
    console.log('Setting up vehicle selections');
    
    $('#truck-list').empty();
    $('#trailer-list').empty();
    
    // loading
    $('#truck-list').html('<div class="loading">Đang tải...</div>');
    $('#trailer-list').html('<div class="loading">Đang tải...</div>');
    
    $('#truck-list').empty();
    if (trucks && trucks.length > 0) {
        console.log('Adding trucks to UI');
        
        const truckPromises = trucks.map(async (truck) => {
            let icon = 'fa-truck';
            if (truck.type === 'highway') {
                icon = 'fa-truck-moving';
            }
            
            const imagePath = `${IMAGE_BASE_PATH}${truck.model}.png`;
            const hasImage = imageCache[imagePath] === true;
            
            console.log(`Truck ${truck.name}, model: ${truck.model}, has image: ${hasImage}`);
            
            let vehicleDisplay = '';
            if (hasImage) {
                vehicleDisplay = `<img src="${imagePath}" loading="lazy" class="vehicle-image" alt="${truck.name}" />`;
            } else {
                vehicleDisplay = `<i class="fas ${icon} vehicle-icon"></i>`;
            }
            
            return `
                <div class="vehicle-item hardware-accelerated" data-type="${truck.type}" data-model="${truck.model}">
                    ${vehicleDisplay}
                    <div class="vehicle-name">${truck.name}</div>
                    <div class="vehicle-desc">${truck.label}</div>
                </div>
            `;
        });
        
        const truckElements = await Promise.all(truckPromises);
        $('#truck-list').append(truckElements.join(''));
    } else {
        console.warn('No trucks available to display');
        $('#truck-list').append('<div class="no-vehicles">Không có xe tải nào khả dụng</div>');
    }
    
    $('#trailer-list').empty();
    if (trailers && trailers.length > 0) {
        console.log('Adding trailers to UI');
        
        const trailerPromises = trailers.map(async (trailer) => {
            let icon = 'fa-trailer';
            
            if (trailer.model.includes('tanker')) {
                icon = 'fa-truck-container';
            } else if (trailer.model.includes('logs')) {
                icon = 'fa-tree';
            } else if (trailer.model.includes('tr4')) {
                icon = 'fa-car';
            }
            
            const imagePath = `${IMAGE_BASE_PATH}${trailer.model}.png`;
            const hasImage = imageCache[imagePath] === true;
            
            // console.log(`Trailer ${trailer.name}, model: ${trailer.model}, has image: ${hasImage}`);
            
            let vehicleDisplay = '';
            if (hasImage) {
                vehicleDisplay = `<img src="${imagePath}" loading="lazy" class="vehicle-image" alt="${trailer.name}" />`;
            } else {
                vehicleDisplay = `<i class="fas ${icon} vehicle-icon"></i>`;
            }
            
            return `
                <div class="vehicle-item hardware-accelerated" data-model="${trailer.model}">
                    ${vehicleDisplay}
                    <div class="vehicle-name">${trailer.name}</div>
                    <div class="vehicle-desc">${trailer.label}</div>
                </div>
            `;
        });
        
        const trailerElements = await Promise.all(trailerPromises);
        $('#trailer-list').append(trailerElements.join(''));
    } else {
        console.warn('No trailers available to display');
        $('#trailer-list').append('<div class="no-vehicles">Không có trailer nào khả dụng</div>');
    }
    
    $('#truck-list').off('click').on('click', '.vehicle-item', function() {
        const vehicleType = $(this).data('type');
        const vehicleModel = $(this).data('model');
        
        console.log('Selected truck:', vehicleModel, 'type:', vehicleType);
        
        $(this).addClass('selected');
        
        setTimeout(() => {
            closeAllMenus();
            $.post('https://riot-truckjob/startTruckJob', JSON.stringify({
                vehicleType: vehicleType,
                vehicleModel: vehicleModel
            }));
        }, 300);
    });
    
    $('#trailer-list').off('click').on('click', '.vehicle-item', function() {
        const trailerModel = $(this).data('model');
        
        // console.log('Selected trailer:', trailerModel);
        
        $(this).addClass('selected');
        
        setTimeout(() => {
            closeAllMenus();
            $.post('https://riot-truckjob/startContainerJob', JSON.stringify({
                trailerModel: trailerModel
            }));
        }, 300);
    });
}

function closeAllMenus() {
    $('#truck-job-container').css('display', 'none');
    $('.menu-container').removeClass('active');
    $('.vehicle-item').removeClass('selected');
    if (requestAnimId) {
        cancelAnimationFrame(requestAnimId);
        requestAnimId = null;
    }
} 