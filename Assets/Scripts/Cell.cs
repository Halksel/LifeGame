using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Cell : MonoBehaviour {
	public GameObject aliveCube;
	public GameObject deadCube;
	private CellMgr cellMgr = CellMgr.Instance;

	[SerializeField]
	private bool isAlive;
	public int x,y;

	void Awake () {  
		aliveCube.SetActive (true);  
		deadCube.SetActive (false);  
		isAlive = false;  
	}
	public void Init(int _x,int _y,bool _isAlive){
		x = _x;
		y = _y;
		isAlive = _isAlive;
		if(isAlive){
			Birth();
		}
		else{
			Die();
		}
	}
	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetMouseButtonDown(0)){
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);  
			RaycastHit hit = new RaycastHit();  

			if (Physics.Raycast(ray, out hit)){ 
				if (hit.collider.gameObject.transform.parent && hit.collider.gameObject.transform.parent.GetComponent<Cell>()) {
					Cell cell = hit.collider.gameObject.transform.parent.GetComponent<Cell> ();  
					if (cell != null) {
						if (cell.isAlive) {  
							cell.Die ();  
						} else {  
							cell.Birth ();  
						}
					}
				}
			}  
		}
	}
		
	public virtual bool PastTurn(){
		Cell[,] cells = cellMgr.cells;
		int count = 0;
		for(int dx = -1; dx <=1 ;++dx){
			for(int dy = -1; dy <= 1;++dy){
				if(dx == 0 && dy == 0) continue;
				int nx = x + dx,ny = y + dy;
				if(cellMgr.IsValue(nx,ny) && cells[nx,ny].isAlive){
					++count;
				}
			}
		}
		if(isAlive){ // 前ターン生存なら
			bool[] birth = cellMgr.birth;
			bool flag = false;
			for(int i = 0; i < 10; ++i){
				if(i == count)
					flag |= birth[i];
			}
			if(flag) Birth();
			else 	 Die();
		}
		else{
			bool[] death = cellMgr.death;
			bool flag = false;
			for (int i = 0; i < 10; ++i) {
				if(i == count)
					flag |= death [i];
			}
			if(flag) Birth();
		}
		return false;
	}
	public void Birth() {  
		deadCube.SetActive (false);  
		aliveCube.SetActive (true);  
	} 
	public void Die() {  
		deadCube.SetActive (true);  
		aliveCube.SetActive (false);  
	} 
	public void Sync(){
		isAlive = aliveCube.activeSelf;	
	}
}
