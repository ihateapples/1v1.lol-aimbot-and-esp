// ==UserScript==
// @name         1v1.LOL SHITTERR
// @namespace    http://tampermonkey.net/
// @version      0.5
// @description  ESP & Aimbot
// @author       yef#4586
// @match        *://1v1.lol/*
// @icon         https://www.google.com/s2/favicons?domain=1v1.lol
// @grant        none
// @run-at       document-start
// @antifeature  ads
// ==/UserScript==

const searchSize = 300;
const threshold = 4.5;
const aimbotSpeed = 0.15;

let aimbotEnabled = false;
let espEnabled = true;
let wireframeEnabled = false;

const WebGL = WebGL2RenderingContext.prototype;

HTMLCanvasElement.prototype.getContext = new Proxy( HTMLCanvasElement.prototype.getContext, {
	apply( target, thisArgs, args ) {

		if ( args[ 1 ] ) {

			args[ 1 ].preserveDrawingBuffer = true;

		}

		return Reflect.apply( ...arguments );

	}
} );

WebGL.shaderSource = new Proxy( WebGL.shaderSource, {
	apply( target, thisArgs, args ) {

		if ( args[ 1 ].indexOf( 'gl_Position' ) > - 1 ) {

			args[ 1 ] = args[ 1 ].replace( 'void main', `

				out float vDepth;
				uniform bool enabled;
				uniform float threshold;

				void main

			` ).replace( /return;/, `

				vDepth = gl_Position.z;

				if ( enabled && vDepth > threshold ) {

					gl_Position.z = 1.0;

				}

			` );

		} else if ( args[ 1 ].indexOf( 'SV_Target0' ) > - 1 ) {

			args[ 1 ] = args[ 1 ].replace( 'void main', `

				in float vDepth;
				uniform bool enabled;
				uniform float threshold;

				void main

			` ).replace( /return;/, `

				if ( enabled && vDepth > threshold ) {

					SV_Target0 = vec4( 1.0, 0.0, 0.0, 1.0 );

				}

			` );

		}

		return Reflect.apply( ...arguments );

	}
} );

WebGL.getUniformLocation = new Proxy( WebGL.getUniformLocation, {
	apply( target, thisArgs, [ program, name ] ) {

		const result = Reflect.apply( ...arguments );

		if ( result ) {

			result.name = name;
			result.program = program;

		}

		return result;

	}
} );

WebGL.uniform4fv = new Proxy( WebGL.uniform4fv, {
	apply( target, thisArgs, args ) {

		if ( args[ 0 ].name === 'hlslcc_mtx4x4unity_ObjectToWorld' ) {

			args[ 0 ].program.isUIProgram = true;

		}

		return Reflect.apply( ...arguments );

	}
} );

let movementX = 0, movementY = 0;
let count = 0;

WebGL.drawElements = new Proxy( WebGL.drawElements, {
	apply( target, thisArgs, args ) {

		const program = thisArgs.getParameter( thisArgs.CURRENT_PROGRAM );

		if ( ! program.uniforms ) {

			program.uniforms = {
				enabled: thisArgs.getUniformLocation( program, 'enabled' ),
				threshold: thisArgs.getUniformLocation( program, 'threshold' )
			};

		}

		const couldBePlayer = args[ 1 ] > 4000;

		thisArgs.uniform1i( program.uniforms.enabled, espEnabled && couldBePlayer );
		thisArgs.uniform1f( program.uniforms.threshold, threshold );

		args[ 0 ] = wireframeEnabled && ! program.isUIProgram && args[ 1 ] > 6 ? thisArgs.LINES : args[ 0 ];

		Reflect.apply( ...arguments );

		if ( aimbotEnabled && couldBePlayer ) {

			const width = Math.min( searchSize, thisArgs.canvas.width );
			const height = Math.min( searchSize, thisArgs.canvas.height );

			const pixels = new Uint8Array( width * height * 4 );

			const centerX = thisArgs.canvas.width / 2;
			const centerY = thisArgs.canvas.height / 2;

			const x = Math.floor( centerX - width / 2 );
			const y = Math.floor( centerY - height / 2 );

			thisArgs.readPixels( x, y, width, height, thisArgs.RGBA, thisArgs.UNSIGNED_BYTE, pixels );

			for ( let i = 0; i < pixels.length; i += 4 ) {

				if ( pixels[ i ] === 255 && pixels[ i + 1 ] === 0 && pixels[ i + 2 ] === 0 && pixels[ i + 3 ] === 255 ) {

					const idx = i / 4;

					const dx = idx % width;
					const dy = ( idx - dx ) / width;

					movementX += ( x + dx - centerX );
					movementY += - ( y + dy - centerY );

					count ++;

				}

			}

		}

	}
} );

window.requestAnimationFrame = new Proxy( window.requestAnimationFrame, {
	apply( target, thisArgs, args ) {

		args[ 0 ] = new Proxy( args[ 0 ], {
			apply() {

				const isPlaying = document.querySelector( 'canvas' ).style.cursor === 'none';

                const v = isPlaying && aimbotEnabled ? '' : 'none';

                if ( v !== rangeEl.style.display ) {

                    rangeEl.style.display = v;

                }

				if ( count > 0 && isPlaying ) {

					const f = aimbotSpeed / count;

					movementX *= f;
					movementY *= f;

					window.dispatchEvent( new MouseEvent( 'mousemove', { movementX, movementY } ) );

					! rangeEl.classList.contains( 'range-active' ) && rangeEl.classList.add( 'range-active' );

				} else {

					rangeEl.classList.contains( 'range-active' ) && rangeEl.classList.remove( 'range-active' );

				}

				movementX = 0;
				movementY = 0;
				count = 0;

				return Reflect.apply( ...arguments );

			}
		} );

		return Reflect.apply( ...arguments );

	}
} )

const value = parseInt( new URLSearchParams( window.location.search ).get( 'showAd' ), 16 );

const shouldShowAd = isNaN( value ) || Date.now() - value < 0 || Date.now() - value > 10 * 60 * 1000;

const el = document.createElement( 'div' );

el.innerHTML = `<style>

.dialog {
	position: absolute;
	left: 50%;
	top: 50%;
	padding: 20px;
	background: #4a1e24;
	color: #0593ff;
	transform: translate(-50%, -50%);
	text-align: center;
	z-index: 999999;
	font-family: cursive;
}

.dialog * {
	color: #0593ff;
}

.close {
	position: absolute;
	right: 5px;
	top: 5px;
	width: 20px;
	height: 20px;
	opacity: 0.5;
	cursor: pointer;
}

.close:before, .close:after {
	content: ' ';
	position: absolute;
	left: 50%;
	top: 50%;
	width: 100%;
	height: 20%;
	transform: translate(-50%, -50%) rotate(-45deg);
	background: #0593ff;
}

.close:after {
	transform: translate(-50%, -50%) rotate(45deg);
}

.close:hover {
	opacity: 1;
}

.btn {
	cursor: pointer;
	padding: 0.5em;
	background: blue;
	border: 3px solid rgba(0, 0, 0, 0.2);
}

.btn:active {
	transform: scale(0.8);
}

.msg {
	position: absolute;
	left: 10px;
	bottom: 650px;
	background: #4a1e24;
	color: #0593ff;
	font-family: cursive;
	font-weight: bolder;
	padding: 15px;
	animation: msg 0.2s forwards, msg 0.2s reverse forwards 2s;
	z-index: 999999;
	pointer-events: none;
}

@keyframes msg {
	from {
		transform: translate(-120%, 0);
	}

	to {
		transform: none;
	}
}

.range {
	position: absolute;
	left: 50%;
	top: 50%;
	width: ${searchSize}px;
	height: ${searchSize}px;
	max-width: 100%;
	max-height: 100%;
	border: 1px solid white;
	transform: translate(-50%, -50%);
}

.range-active {
	border: 2px solid red;
}

</style>
<div class="dialog">${shouldShowAd ? `<big><big>1v1.lol shitter By yef#4586</big>
	<br>
	<br>
	[T] to toggle aimbot
	<br>
	[M] to toggle ESP
	<br>
	[N] to toggle wireframe
	<br>
	[H] to show/hide
	<br>
	<br>
	By RPN Panda
	<br></big>` : `<div class="close" onclick="this.parentNode.style.display='none';"></div>
	<br>
	<br>
	<div style="display: grid; grid-template-columns: 1fr 1fr; grid-gap: 5px;">
	</div>
	` }
</div>
<div class="msg" style="display: none;"></div>
<div class="range" style="display: none;"></div>`;

const msgEl = el.querySelector( '.msg' );
const dialogEl = el.querySelector( '.dialog' );

const rangeEl = el.querySelector( '.range' );

window.addEventListener( 'DOMContentLoaded', function () {

	while ( el.children.length > 0 ) {

		document.body.appendChild( el.children[ 0 ] );

	}

	if ( shouldShowAd ) {

		const url = new URL( window.location.href );

		url.searchParams.set( 'RPN', Date.now().toString( 16 ) );
		url.searchParams.set( 'scriptVersion', GM.info.script.version );

	}

} );

window.addEventListener( 'keyup', function ( event ) {

	switch ( String.fromCharCode( event.keyCode ) ) {

		case 'M' :

			espEnabled = ! espEnabled;

			showMsg( 'ESP', espEnabled - yef#4586 );

			break;

		case 'N' :

			wireframeEnabled = ! wireframeEnabled;

			showMsg( 'Wireframe', wireframeEnabled - yef#4586 );

			break;

		case 'T' :

			aimbotEnabled = ! aimbotEnabled;

			showMsg( 'Aimbot', aimbotEnabled - yef#4586 );

			break;

		case 'H' :

			dialogEl.style.display = dialogEl.style.display === '' ? 'none' : '';

			break;

	}

} );

function showMsg( name, bool ) {

	msgEl.innerText = name + ': ' + ( bool ? 'ON' : 'OFF' );

	msgEl.style.display = 'none';

	void msgEl.offsetWidth;

	msgEl.style.display = '';

}