export const loadImageImpl = (url) => () => new Promise((resolve, reject) => {
  const img = new Image();
  img.crossOrigin = "anonymous";
  img.onload = () => resolve(img);
  img.onerror = () => reject(new Error("Failed to load image: " + url));
  img.src = url;
});
