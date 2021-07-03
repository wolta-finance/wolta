import React, { useRef, useEffect } from 'react';
/* eslint-env browser */
export const randomRange = (fromNum, toNum) => {
	const diff = toNum - fromNum;
	return fromNum + (Math.random() * diff);
};

export const scaleToF = ([x, y, z]) => {
	const f = 100;
	const multiplier = f / (f + z);
	return [x * multiplier, y * multiplier];
};

export const makeCircularBuffer = (size, initial = []) => {
	const buffer = Array(size).fill(true);
	initial.forEach((item, i) => {
		buffer[i] = item;
	});
	let position = 0;

	return {
		insert(item) {
			buffer[position] = item;
			if (position < (size - 1)) {
				position += 1;
			} else {
				position = 0;
			}
		},
		read() {
			return buffer;
		},
		getCurrentPosition() {
			return position;
		},
		getSize() {
			return size;
		},
	};
};

export const doNothing = duration => passthrough => new Promise((resolve) => {
	const resolveWithPassthrough = () => resolve(passthrough);
	setTimeout(resolveWithPassthrough, duration * 1000);
});

const renderFlight = (
	context,
	width,
	height,
	particles,
) => new Promise((resolve) => {
	const buffer = makeCircularBuffer(1000, particles);
	const lines = buffer.read();
	function drawLine(x, y, fromZ, toZ) {
		context.moveTo(...scaleToF([x, y, fromZ]));
		context.lineTo(...scaleToF([x, y, toZ]));
	}

	function populateLines(q) {
		Array(q).fill(true).forEach(() => {
			// x, y, length, z
			buffer.insert([
				randomRange(-width / 2, width / 2),
				randomRange(-width / 2, width / 2),
				randomRange(0, 100),
				randomRange(0, 100)]);
		});
	}

	function update() {
		populateLines(10);
		context.clearRect(-width / 2, -height / 2, width, height);
        let current = 0;
		for (let i = 0; i < lines.length; i += 1) {
			context.beginPath();

			if ((lines[i][3] + lines[i][2]) > 0) {
				lines[i][3] -= 2;
				drawLine(
					lines[i][0],
					lines[i][1],
					lines[i][3] > 0 ? lines[i][3] : 0,
					lines[i][3] + lines[i][2],
				);
			}
			context.lineWidth = 1; // eslint-disable-line no-param-reassign
            context.strokeStyle = 'black';
            current = current < 100 ? current + 1 : 0 ;
			context.stroke();
		}

		requestAnimationFrame(update);
	}

	update();
});

const Canvas = () => {
    const canvasEl = useRef(null);

    useEffect(() => {
        const context = canvasEl.current.getContext('2d');
        let segments;
        let particles;
        canvasEl.current.width = window.innerWidth * 1;
        canvasEl.current.height = window.innerWidth  * 1;
        context.translate(canvasEl.current.width / 2, canvasEl.current.height / 2);

        renderFlight(
            context,
            canvasEl.current.width,
            canvasEl.current.height,
            particles,
        )
    });

    return (<canvas ref={canvasEl} className="w-full h-screen absolute bg-white" id="canvas"></canvas>)
}

export default Canvas;